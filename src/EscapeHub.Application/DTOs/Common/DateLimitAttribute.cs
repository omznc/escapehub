using System.ComponentModel.DataAnnotations;

namespace EscapeHub.Application.DTOs.Common;

public class DateLimitAttribute : RangeAttribute
{
    public DateLimitAttribute() : base(typeof(DateTime), "2000-01-01T00:00:00", "2100-12-31T23:59:59")
    {
        ParseLimitsInInvariantCulture = true;
        ConvertValueInInvariantCulture = true;
        ErrorMessage = "Enter a date between 01.01.2000 and 31.12.2100.";
    }
}
