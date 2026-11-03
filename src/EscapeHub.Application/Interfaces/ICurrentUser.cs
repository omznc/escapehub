namespace EscapeHub.Application.Interfaces;

public interface ICurrentUser
{
    int Id { get; }
    bool IsAdmin { get; }
    bool IsManager { get; }
    bool IsClient { get; }
}
