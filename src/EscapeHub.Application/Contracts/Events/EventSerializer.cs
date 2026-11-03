using System.Text.Json;

namespace EscapeHub.Application.Contracts.Events;

public static class EventSerializer
{
    public static readonly JsonSerializerOptions Options = new(JsonSerializerDefaults.Web);
}
