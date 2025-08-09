using System;
using System.Text;
using System.Text.Json;
using RabbitMQ.Client;
using RabbitMQ.Client.Exceptions;
using Microsoft.Extensions.Logging;
using MyClub.Services.Interfaces;


namespace MyClub.Services.Services
{
    public class RabbitMQService : IRabbitMQService
    {
        private readonly ILogger<RabbitMQService> _logger;
        private readonly string _exchangeName = "EmailExchange";
        private readonly string _hostname;
        private readonly int _port;
        private readonly string _username;
        private readonly string _password;

        public RabbitMQService(ILogger<RabbitMQService> logger)
        {
            _logger = logger;
            _hostname = "localhost";
            _port = 5672;
            _username = "guest";
            _password = "guest";
        }

        public void SendMessage<T>(string routingKey, T message)
        {
            try
            {
                // Create a new connection factory each time
                var factory = new ConnectionFactory
                {
                    HostName = _hostname,
                    Port = _port,
                    UserName = _username,
                    Password = _password
                };

                // Create a connection and channel
                using var connection = factory.CreateConnection();
                using var channel = connection.CreateModel();

                // Declare the exchange
                channel.ExchangeDeclare(
                    exchange: _exchangeName,
                    type: ExchangeType.Direct,
                    durable: true,
                    autoDelete: false);

                // Serialize the message to JSON
                var jsonMessage = JsonSerializer.Serialize(message);
                var body = Encoding.UTF8.GetBytes(jsonMessage);

                // Create persistent message properties
                var properties = channel.CreateBasicProperties();
                properties.Persistent = true;

                // Publish the message
                channel.BasicPublish(
                    exchange: _exchangeName,
                    routingKey: routingKey,
                    basicProperties: properties,
                    body: body);

                _logger.LogInformation($"Message sent to exchange: {_exchangeName} with routing key: {routingKey}");
            }
            catch (BrokerUnreachableException ex)
            {
                _logger.LogError(ex, $"RabbitMQ broker unreachable at {_hostname}:{_port}. Ensure Docker/RabbitMQ is running and reachable.");
                Console.WriteLine($"ERROR: RabbitMQ broker unreachable at {_hostname}:{_port}. Ensure Docker/RabbitMQ is running and reachable.");
                // Don't throw - allow the application to continue without sending message
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error sending message to RabbitMQ exchange: {_exchangeName}");
                Console.WriteLine($"ERROR: Failed to send message to RabbitMQ: {ex.Message}");
                // Don't throw - allow the application to continue without sending message
            }
        }
    }
}