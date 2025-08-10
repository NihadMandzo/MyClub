using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using Newtonsoft.Json;
using MyClub.Subscriber;

Console.WriteLine("Starting MyClub Email Subscriber...");
Console.WriteLine("Sleeping to wait for Rabbit...");
await Task.Delay(10000);
await Task.Delay(1000);
Console.WriteLine("Consuming Queue Now");

try
{
    // Load environment variables from .env by traversing up the directory tree (if present)
    try { DotNetEnv.Env.TraversePath().Load(); Console.WriteLine("Loaded environment from .env"); } catch { /* ignore */ }

    // Small helpers to get env vars with fallback and defaults
    static string GetEnv(string defaultValue, params string[] keys)
    {
        foreach (var k in keys)
        {
            var v = Environment.GetEnvironmentVariable(k);
            if (!string.IsNullOrWhiteSpace(v)) return v;
        }
        return defaultValue;
    }
    static int GetEnvInt(int defaultValue, params string[] keys)
    {
        var s = GetEnv(string.Empty, keys);
        return int.TryParse(s, out var i) ? i : defaultValue;
    }

    var hostname = GetEnv("localhost", "_rabbitMqHost", "RABBITMQ_HOST");
    var username = GetEnv("guest", "_rabbitMqUser", "RABBITMQ_USERNAME");
    var password = GetEnv("guest", "_rabbitMqPassword", "RABBITMQ_PASSWORD");
    var port = GetEnvInt(5672, "_rabbitMqPort", "RABBITMQ_PORT");

    var factory = new ConnectionFactory()
    {
        HostName = hostname,
        Port = port,
        UserName = username,
        Password = password
    };

    Console.WriteLine($"Connecting to RabbitMQ at {factory.HostName}:{factory.Port} with user {factory.UserName}");

    factory.ClientProvidedName = "MyClub Email Consumer";
    var connection = factory.CreateConnection();
    var channel = connection.CreateModel();

    string exchangeName = "EmailExchange";
    string routingKey = "order_notifications";
    string queueName = GetEnv("email_notifications_q", "MAIL_QUEUE_NAME"); // set to 'mail_sending' if desired

    Console.WriteLine($"Declaring exchange '{exchangeName}' (Direct)...");
    channel.ExchangeDeclare(exchangeName, ExchangeType.Direct, true, false, null);
    
    Console.WriteLine($"Declaring queue '{queueName}'...");
    channel.QueueDeclare(queue: queueName, durable: true, exclusive: false, autoDelete: false, arguments: null);
    
    Console.WriteLine($"Binding queue '{queueName}' to exchange '{exchangeName}' with routing key '{routingKey}'...");
    channel.QueueBind(queueName, exchangeName, routingKey, null);

    // Configure basic QoS to avoid over-fetching (kept modest)
    channel.BasicQos(0, 5, false);

    var consumer = new EventingBasicConsumer(channel);

    consumer.Received += async (model, ea) =>
    {
        Console.WriteLine("Message received!");
        var body = ea.Body.ToArray();
        var message = Encoding.UTF8.GetString(body);
        Console.WriteLine($"Message content: {message}");

        var maxAttempts = 3;
        var attempt = 0;
        var backoffMs = 1000;
        bool success = false;

        try
        {
            var entity = JsonConvert.DeserializeObject<MyClub.Model.EmailMessage>(message);
            if (entity == null)
            {
                Console.WriteLine("Invalid message payload. Nacking without requeue.");
                channel.BasicNack(ea.DeliveryTag, false, false);
                return;
            }

            while (attempt < maxAttempts && !success)
            {
                attempt++;
                success = await MailSender.SendEmail(entity);
                if (!success)
                {
                    Console.WriteLine($"Send failed (attempt {attempt}/{maxAttempts}). Backing off {backoffMs}ms...");
                    await Task.Delay(backoffMs);
                    backoffMs *= 2;
                }
            }

            if (success)
            {
                channel.BasicAck(ea.DeliveryTag, false);
            }
            else
            {
                Console.WriteLine("Max attempts reached. Nacking without requeue.");
                channel.BasicNack(ea.DeliveryTag, false, false);
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"ERROR processing message: {ex.Message}");
            channel.BasicNack(ea.DeliveryTag, false, false);
        }
    };

    Console.WriteLine($"Starting to consume from queue '{queueName}'...");
    channel.BasicConsume(queue: queueName, autoAck: false, consumer: consumer);

    Console.WriteLine("[*] Waiting for order notification messages.");
    Thread.Sleep(Timeout.Infinite);
    // Unreachable due to infinite sleep, but kept for completeness
    channel.Close();
    connection.Close();
}
catch (Exception ex)
{
    Console.WriteLine($"ERROR: {ex.Message}");
    if (ex.InnerException != null)
    {
        Console.WriteLine($"Inner exception: {ex.InnerException.Message}");
    }
    Console.WriteLine("Press [enter] to exit...");
    Console.ReadLine();
}
