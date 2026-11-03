namespace EscapeHub.Application.DTOs.Common;

public static class ValidationPatterns
{
    public const string Phone = @"^\+?[0-9][0-9 /-]{5,18}[0-9]$";
    public const string PhoneMessage = "Enter a valid phone number, for example +387 61 123 456.";
    public const string Time = @"^([01][0-9]|2[0-3]):[0-5][0-9]$";
    public const string TimeMessage = "Enter the time in the format HH:mm, for example 18:30.";
    public const string EmailMessage = "Enter a valid email address, for example name@example.com.";
}
