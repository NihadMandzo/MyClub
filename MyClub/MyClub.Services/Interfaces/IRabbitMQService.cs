namespace MyClub.Services.Interfaces
{
    public interface IRabbitMQService
    {
        void SendMessage<T>(string queueName, T message);
    }
}