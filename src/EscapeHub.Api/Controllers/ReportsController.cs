using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EscapeHub.Api.Reports;
using EscapeHub.Application.DTOs.Reports;
using EscapeHub.Domain.Constants;
using EscapeHub.Infrastructure.Services;

namespace EscapeHub.Api.Controllers;

[ApiController]
[Route("api/reports")]
[Authorize(Roles = Roles.Staff)]
public class ReportsController : ControllerBase
{
    private readonly ReportService _reports;

    public ReportsController(ReportService reports) => _reports = reports;

    [HttpGet(ReportNames.Bookings)]
    public Task<ReportResult<BookingsReportRow>> Bookings([FromQuery] ReportQuery query) => _reports.GetBookingsAsync(query);

    [HttpGet(ReportNames.Revenue)]
    public Task<ReportResult<RevenueReportRow>> Revenue([FromQuery] ReportQuery query) => _reports.GetRevenueAsync(query);

    [HttpGet(ReportNames.Occupancy)]
    public Task<ReportResult<OccupancyReportRow>> Occupancy([FromQuery] ReportQuery query) => _reports.GetOccupancyAsync(query);

    [HttpGet(ReportNames.TopRooms)]
    public Task<ReportResult<TopRoomReportRow>> TopRooms([FromQuery] ReportQuery query) => _reports.GetTopRoomsAsync(query);

    [HttpGet(ReportNames.TopClients)]
    public Task<ReportResult<TopClientReportRow>> TopClients([FromQuery] ReportQuery query) => _reports.GetTopClientsAsync(query);

    [HttpGet(ReportNames.TopClientsBySpending)]
    public Task<ReportResult<TopClientReportRow>> TopClientsBySpending([FromQuery] ReportQuery query) => _reports.GetTopClientsBySpendingAsync(query);

    [HttpGet(ReportNames.Ratings)]
    public Task<ReportResult<RatingReportRow>> Ratings([FromQuery] ReportQuery query) => _reports.GetRatingsAsync(query);

    [HttpGet(ReportNames.LoyaltyRedemptions)]
    [Authorize(Roles = Roles.Administrator)]
    public Task<ReportResult<RedemptionReportRow>> LoyaltyRedemptions([FromQuery] ReportQuery query) => _reports.GetRedemptionsAsync(query);

    [HttpGet("{report}/export")]
    public async Task<IActionResult> Export(string report, [FromQuery] ExportQuery query)
    {
        var table = await _reports.GetTableAsync(report, query);
        var file = ReportExporter.Export(report, table, query.Format);
        return File(file.Content, file.ContentType, file.FileName);
    }
}
