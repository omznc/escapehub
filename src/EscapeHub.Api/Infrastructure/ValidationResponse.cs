using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using EscapeHub.Application.DTOs.Common;

namespace EscapeHub.Api.Infrastructure;

public static class ValidationResponse
{
    private const string InvalidValue = "The value has an invalid format.";

    public static IActionResult Create(ActionContext context)
    {
        var parameters = context.ActionDescriptor.Parameters
            .Where(p => p.BindingInfo?.BindingSource == BindingSource.Body)
            .Select(p => p.Name)
            .ToHashSet(StringComparer.OrdinalIgnoreCase);
        var errors = new Dictionary<string, string[]>();
        string? bodyMessage = null;

        foreach (var (key, entry) in context.ModelState.Where(e => e.Value is { Errors.Count: > 0 }))
        {
            var messages = entry!.Errors.Select(Message).Distinct().ToArray();
            var field = FieldName(key, parameters);
            if (field == null)
                bodyMessage ??= "The request body is missing or is not valid JSON.";
            else
                errors[field] = messages;
        }

        var response = new ErrorResponse
        {
            Message = errors.Values.FirstOrDefault()?.FirstOrDefault() ?? bodyMessage ?? "The request is not valid.",
            Errors = errors
        };
        return new BadRequestObjectResult(response);
    }

    private static string Message(ModelError error) =>
        string.IsNullOrEmpty(error.ErrorMessage) || error.ErrorMessage.Contains("JSON", StringComparison.Ordinal) || error.Exception != null
            ? InvalidValue
            : error.ErrorMessage;

    private static string? FieldName(string key, HashSet<string> parameters)
    {
        var path = key.StartsWith("$.", StringComparison.Ordinal) ? key[2..] : key;
        if (path is "" or "$" || parameters.Contains(path)) return null;

        var segments = path.Split('.').ToList();
        if (segments.Count > 1 && parameters.Contains(segments[0])) segments.RemoveAt(0);
        return string.Join('.', segments.Select(s => char.ToLowerInvariant(s[0]) + s[1..]));
    }
}
