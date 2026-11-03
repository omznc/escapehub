namespace EscapeHub.Application.Interfaces;

public interface IEventPublisher
{
    bool Publish<T>(string queue, T message);
}
