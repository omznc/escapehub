using System.Text.Json;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;
using EscapeHub.Application.Contracts.Events;
using EscapeHub.Application.Interfaces;
using EscapeHub.Infrastructure.Configuration;

namespace EscapeHub.Infrastructure.Messaging;

public sealed class EventPublisher : IEventPublisher, IDisposable
{
    private static readonly TimeSpan ConfirmTimeout = TimeSpan.FromSeconds(5);

    private readonly ConnectionFactory _factory;
    private readonly ILogger<EventPublisher> _logger;
    private readonly object _lock = new();
    private IConnection? _connection;
    private IModel? _channel;

    public EventPublisher(RabbitMqOptions options, ILogger<EventPublisher> logger)
    {
        _factory = QueueTopology.CreateFactory(options);
        _logger = logger;
    }

    public bool Publish<T>(string queue, T message)
    {
        var body = JsonSerializer.SerializeToUtf8Bytes(message, EventSerializer.Options);
        try
        {
            lock (_lock)
            {
                var channel = GetChannel();
                QueueTopology.Send(channel, queue, body);
                channel.WaitForConfirmsOrDie(ConfirmTimeout);
            }
            _logger.LogInformation("Published {Event} to {Queue}", typeof(T).Name, queue);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to publish {Message} to {Queue}", message, queue);
            return false;
        }
    }

    private IModel GetChannel()
    {
        if (_channel is { IsOpen: true }) return _channel;

        _channel?.Dispose();
        if (_connection is not { IsOpen: true })
        {
            _connection?.Dispose();
            _connection = _factory.CreateConnection();
        }
        _channel = _connection.CreateModel();
        _channel.ConfirmSelect();
        QueueTopology.Declare(_channel);
        return _channel;
    }

    public void Dispose()
    {
        _channel?.Dispose();
        _connection?.Dispose();
    }
}
