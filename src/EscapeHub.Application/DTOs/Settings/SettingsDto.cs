using System.ComponentModel.DataAnnotations;
using EscapeHub.Application.DTOs.Common;

namespace EscapeHub.Application.DTOs.Settings;

public class SettingsDto
{
    public string CompanyName { get; set; } = string.Empty;
    public string ContactEmail { get; set; } = string.Empty;
    public string? ContactPhone { get; set; }
    public int PointsPerPlayer { get; set; }
    public decimal PointsPerCurrencyUnit { get; set; }
    public int CancellationDeadlineHours { get; set; }
    public int ReminderHoursBefore { get; set; }
    public DateTime UpdatedAt { get; set; }
    public string? UpdatedByName { get; set; }
}

public class UpdateSettingsRequest
{
    [Required(ErrorMessage = "Company name is required.")]
    [StringLength(200, ErrorMessage = "Company name can have at most 200 characters.")]
    public string CompanyName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Contact email is required.")]
    [EmailAddress(ErrorMessage = ValidationPatterns.EmailMessage)]
    [StringLength(256, ErrorMessage = "Contact email can have at most 256 characters.")]
    public string ContactEmail { get; set; } = string.Empty;

    [RegularExpression(ValidationPatterns.Phone, ErrorMessage = ValidationPatterns.PhoneMessage)]
    public string? ContactPhone { get; set; }

    [Range(0, 1000, ErrorMessage = "Points per player must be between 0 and 1000.")]
    public int PointsPerPlayer { get; set; }

    [Range(0, 100, ErrorMessage = "Points per currency unit must be between 0 and 100.")]
    public decimal PointsPerCurrencyUnit { get; set; }

    [Range(0, 168, ErrorMessage = "Cancellation deadline must be between 0 and 168 hours.")]
    public int CancellationDeadlineHours { get; set; }

    [Range(1, 168, ErrorMessage = "Reminder time must be between 1 and 168 hours.")]
    public int ReminderHoursBefore { get; set; }
}
