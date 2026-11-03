using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using RabbitMQ.Client.Exceptions;
using EscapeHub.Application.Contracts.Events;
using EscapeHub.Infrastructure.Configuration;
using EscapeHub.Infrastructure.Messaging;

namespace EscapeHub.Worker.Messaging;

public class QueueConsumerService : BackgroundService
{
    private static readonly TimeSpan[] RetryDelays =
        [TimeSpan.FromSeconds(1), TimeSpan.FromSeconds(2), TimeSpan.FromSeconds(4), TimeSpan.FromSeconds(8)];
    private static readonly TimeSpan ConnectDelay = TimeSpan.FromSeconds(5);

    private readonly ConnectionFactory _factory;
    private readonly IServiceScopeFactory _scopes;
    private readonly ILogger<QueueConsumerService> _logger;
    private IConnection? _connection;
    private IModel? _channel;

    public QueueConsumerService(RabbitMqOptions options, IServiceScopeFactory scopes, ILogger<QueueConsumerService> logger)
    {
        _factory = QueueTopology.CreateFactory(options);
        _scopes = scopes;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _connection = await ConnectAsync(stoppingToken);
        _connection.ConnectionShutdown += (_, args) => _logger.LogWarning("RabbitMQ connection closed: {Reason}", args.ReplyText);
        _channel = _connection.CreateModel();
        _channel.BasicQos(prefetchSize: 0, prefetchCount: 5, global: false);
        QueueTopology.Declare(_channel);

        foreach (var queue in EventQueues.All)
        {
            var consumer = new AsyncEventingBasicConsumer(_channel);
            consumer.Received += (_, delivery) => HandleAsync(queue, delivery, stoppingToken);
            _channel.BasicConsume(queue, autoAck: false, consumer);
        }
        _logger.LogInformation("Listening on {Count} queues", EventQueues.All.Length);

        try
        {
            await Task.Delay(Timeout.Infinite, stoppingToken);
        }
        catch (OperationCanceledException)
        {
            _logger.LogInformation("Queue consumer stopped");
        }
    }

    private async Task<IConnection> ConnectAsync(CancellationToken stoppingToken)
    {
        for (var attempt = 1; ; attempt++)
        {
            try
            {
                return _factory.CreateConnection();
            }
            catch (BrokerUnreachableException ex)
            {
                _logger.LogWarning("RabbitMQ is not reachable (attempt {Attempt}): {Error}. Next try in {Delay}s",
                    attempt, ex.Message, ConnectDelay.TotalSeconds);
                await Task.Delay(ConnectDelay, stoppingToken);
            }
        }
    }

    private async Task HandleAsync(string queue, BasicDeliverEventArgs delivery, CancellationToken stoppingToken)
    {
        var body = delivery.Body.ToArray();
        for (var attempt = 0; ; attempt++)
        {
            try
            {
                await using var scope = _scopes.CreateAsyncScope();
                await scope.ServiceProvider.GetRequiredService<EventDispatcher>().DispatchAsync(queue, body);
                _channel!.BasicAck(delivery.DeliveryTag, multiple: false);
                return;
            }
            catch (Exception ex) when (attempt < RetryDelays.Length && !stoppingToken.IsCancellationRequested)
            {
                _logger.LogWarning(ex, "Message from {Queue} failed (attempt {Attempt}). Retry in {Delay}s",
                    queue, attempt + 1, RetryDelays[attempt].TotalSeconds);
                await Task.Delay(RetryDelays[attempt], stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Message from {Queue} failed after {Attempts} attempts. Moving it to {DeadLetter}",
                    queue, attempt + 1, EventQueues.DeadLetter);
                QueueTopology.Send(_channel!, EventQueues.DeadLetter, body);
                _channel!.BasicAck(delivery.DeliveryTag, multiple: false);
                return;
            }
        }
    }

    public override void Dispose()
    {
        _channel?.Dispose();
        _connection?.Dispose();
        base.Dispose();
    }
}
