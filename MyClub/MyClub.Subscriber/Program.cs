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
    string orderNotificationsRoutingKey = "order_notifications";
    string resetPasswordRoutingKey = "reset_password";
    string queueName = GetEnv("email_notifications_q", "MAIL_QUEUE_NAME"); // set to 'mail_sending' if desired
    string resetPasswordQueueName = "reset_password_q";

    Console.WriteLine($"Declaring exchange '{exchangeName}' (Direct)...");
    channel.ExchangeDeclare(exchangeName, ExchangeType.Direct, true, false, null);
    
    Console.WriteLine($"Declaring queue '{queueName}' for order notifications...");
    channel.QueueDeclare(queue: queueName, durable: true, exclusive: false, autoDelete: false, arguments: null);
    
    Console.WriteLine($"Declaring queue '{resetPasswordQueueName}' for reset password emails...");
    channel.QueueDeclare(queue: resetPasswordQueueName, durable: true, exclusive: false, autoDelete: false, arguments: null);
    
    Console.WriteLine($"Binding queue '{queueName}' to exchange '{exchangeName}' with routing key '{orderNotificationsRoutingKey}'...");
    channel.QueueBind(queueName, exchangeName, orderNotificationsRoutingKey, null);
    
    Console.WriteLine($"Binding queue '{resetPasswordQueueName}' to exchange '{exchangeName}' with routing key '{resetPasswordRoutingKey}'...");
    channel.QueueBind(resetPasswordQueueName, exchangeName, resetPasswordRoutingKey, null);

    // Configure basic QoS to avoid over-fetching (kept modest)
    channel.BasicQos(0, 5, false);

    var consumer = new EventingBasicConsumer(channel);
    var resetPasswordConsumer = new EventingBasicConsumer(channel);

    // Consumer for order notifications
    consumer.Received += async (model, ea) =>
    {
        Console.WriteLine("Order notification message received!");
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
            Console.WriteLine($"ERROR processing order notification message: {ex.Message}");
            channel.BasicNack(ea.DeliveryTag, false, false);
        }
    };

    // Consumer for reset password emails
    resetPasswordConsumer.Received += async (model, ea) =>
    {
        Console.WriteLine("Reset password email message received!");
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
            Console.WriteLine($"ERROR processing reset password email message: {ex.Message}");
            channel.BasicNack(ea.DeliveryTag, false, false);
        }
    };

    Console.WriteLine($"Starting to consume from queue '{queueName}' for order notifications...");
    channel.BasicConsume(queue: queueName, autoAck: false, consumer: consumer);
    
    Console.WriteLine($"Starting to consume from queue '{resetPasswordQueueName}' for reset password emails...");
    channel.BasicConsume(queue: resetPasswordQueueName, autoAck: false, consumer: resetPasswordConsumer);

    Console.WriteLine("[*] Waiting for messages. Press Ctrl+C to exit.");
    
    // Use a more robust approach for keeping the application alive
    var exitEvent = new ManualResetEventSlim(false);
    Console.CancelKeyPress += (_, e) =>
    {
        e.Cancel = true;
        Console.WriteLine("\nReceived exit signal. Shutting down gracefully...");
        exitEvent.Set();
    };
    
    exitEvent.Wait();
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
