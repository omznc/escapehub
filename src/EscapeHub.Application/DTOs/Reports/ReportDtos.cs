using System.ComponentModel.DataAnnotations;
using EscapeHub.Application.DTOs.Common;

namespace EscapeHub.Application.DTOs.Reports;

public static class ReportNames
{
    public const string Bookings = "bookings";
    public const string Revenue = "revenue";
    public const string Occupancy = "occupancy";
    public const string TopRooms = "top-rooms";
    public const string TopClients = "top-clients";
    public const string TopClientsBySpending = "top-clients-by-spending";
    public const string Ratings = "ratings";
    public const string LoyaltyRedemptions = "loyalty-redemptions";
}

public static class ReportOptions
{
    public const string Day = "day";
    public const string Month = "month";
    public const string Pdf = "pdf";
    public const string Csv = "csv";
}

public class ReportQuery
{
    [DateLimit]
    public DateTime? From { get; set; }

    [DateLimit]
    public DateTime? To { get; set; }

    public int? RoomId { get; set; }

    [Range(1, 100, ErrorMessage = "Top must be between 1 and 100.")]
    public int Top { get; set; } = 10;

    [RegularExpression("^(" + ReportOptions.Day + "|" + ReportOptions.Month + ")$", ErrorMessage = "Group by must be day or month.")]
    public string GroupBy { get; set; } = ReportOptions.Month;
}

public class ExportQuery : ReportQuery
{
    [RegularExpression("^(" + ReportOptions.Pdf + "|" + ReportOptions.Csv + ")$", ErrorMessage = "Format must be pdf or csv.")]
    public string Format { get; set; } = ReportOptions.Pdf;
}

public class ReportResult<TRow>
{
    public string Title { get; set; } = string.Empty;
    public DateTime From { get; set; }
    public DateTime To { get; set; }
    public List<TRow> Rows { get; set; } = new();
}

public record BookingsReportRow(DateTime Date, int Total, int Pending, int Confirmed, int Completed, int Cancelled, int NoShow, int Rejected);

public record RevenueReportRow(string Period, int Bookings, decimal Revenue, decimal Discounts);

public record OccupancyReportRow(int RoomId, string RoomName, int TotalSlots, int BookedSlots, double OccupancyPercent);

public record TopRoomReportRow(int RoomId, string RoomName, int Bookings, decimal Revenue, double AveragePlayers);

public record TopClientReportRow(int ClientId, string ClientName, string Email, int Bookings, decimal TotalSpent);

public record RatingReportRow(int RoomId, string RoomName, double AverageRating, int ReviewCount, int OneStar, int TwoStars, int ThreeStars, int FourStars, int FiveStars);

public record RedemptionReportRow(int RewardId, string RewardName, int Redemptions, int PointsSpent, int Used, int Unused);

public class ReportTable
{
    public string Title { get; set; } = string.Empty;
    public DateTime From { get; set; }
    public DateTime To { get; set; }
    public List<string> Columns { get; set; } = new();
    public List<List<string>> Rows { get; set; } = new();
}

public record ExportedFile(byte[] Content, string ContentType, string FileName);
