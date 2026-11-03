namespace EscapeHub.Infrastructure.Extensions;

public static class TextExtensions
{
    public static string Counted(this int count, string one, string many) => $"{count} {(count == 1 ? one : many)}";
}
