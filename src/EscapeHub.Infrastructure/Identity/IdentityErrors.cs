using Microsoft.AspNetCore.Identity;
using EscapeHub.Application.Exceptions;

namespace EscapeHub.Infrastructure.Identity;

public static class IdentityErrors
{
    public static void ThrowIfFailed(IdentityResult result, string passwordField = "password")
    {
        if (result.Succeeded) return;

        var errors = result.Errors
            .Select(e => (Field: FieldFor(e.Code, passwordField), e.Description))
            .Where(e => e.Field != null)
            .GroupBy(e => e.Field!)
            .ToDictionary(g => g.Key, g => g.Select(e => e.Description).ToArray());
        throw new BusinessException(result.Errors.First().Description, errors);
    }

    private static string? FieldFor(string code, string passwordField) => code switch
    {
        "DuplicateUserName" or "InvalidUserName" => "username",
        "DuplicateEmail" or "InvalidEmail" => "email",
        "PasswordMismatch" => "currentPassword",
        _ when code.StartsWith("Password", StringComparison.Ordinal) => passwordField,
        _ => null
    };
}
