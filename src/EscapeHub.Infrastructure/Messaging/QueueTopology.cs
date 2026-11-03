using RabbitMQ.Client;
using EscapeHub.Application.Contracts.Events;
using EscapeHub.Infrastructure.Configuration;

namespace EscapeHub.Infrastructure.Messaging;

public static class QueueTopology
{
    public static ConnectionFactory CreateFactory(RabbitMqOptions options) => new()
    {
        HostName = options.Host,
        Port = options.Port,
        UserName = options.Username,
        Password = options.Password,
        VirtualHost = options.VirtualHost,
        DispatchConsumersAsync = true,
        AutomaticRecoveryEnabled = true,
        ClientProvidedName = "escapehub"
    };

    public static void Declare(IModel channel)
    {
        channel.QueueDeclare(EventQueues.DeadLetter, durable: true, exclusive: false, autoDelete: false);
        foreach (var queue in EventQueues.All)
            channel.QueueDeclare(queue, durable: true, exclusive: false, autoDelete: false);
    }

    public static void Send(IModel channel, string queue, byte[] body)
    {
        var properties = channel.CreateBasicProperties();
        properties.Persistent = true;
        properties.ContentType = "application/json";
        channel.BasicPublish(exchange: string.Empty, routingKey: queue, mandatory: false, basicProperties: properties, body: body);
    }
}
