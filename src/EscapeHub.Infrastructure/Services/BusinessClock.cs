using Microsoft.Extensions.Configuration;
using EscapeHub.Infrastructure.Configuration;

namespace EscapeHub.Infrastructure.Services;

public class BusinessClock
{
    private readonly TimeZoneInfo _zone;

    public BusinessClock(TimeZoneInfo zone) => _zone = zone;

    public static BusinessClock From(IConfiguration configuration) =>
        new(TimeZoneInfo.FindSystemTimeZoneById(configuration.GetRequired("APP_TIME_ZONE")));

    public DateTime Now => TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, _zone);

    public DateTime Today => Now.Date;

    public DateTime UtcDayStart(DateTime localDate) =>
        TimeZoneInfo.ConvertTimeToUtc(DateTime.SpecifyKind(localDate.Date, DateTimeKind.Unspecified), _zone);

    public DateTime UtcDayEnd(DateTime localDate) => UtcDayStart(localDate.AddDays(1));
}
