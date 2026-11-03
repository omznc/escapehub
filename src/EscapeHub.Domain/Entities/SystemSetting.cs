namespace EscapeHub.Domain.Entities;

public class SystemSetting : BaseEntity
{
    public string CompanyName { get; set; } = string.Empty;
    public string ContactEmail { get; set; } = string.Empty;
    public string? ContactPhone { get; set; }
    public int PointsPerPlayer { get; set; }
    public decimal PointsPerCurrencyUnit { get; set; }
    public int CancellationDeadlineHours { get; set; }
    public int ReminderHoursBefore { get; set; }

    public int? UpdatedById { get; set; }
    public ApplicationUser? UpdatedBy { get; set; }
}
