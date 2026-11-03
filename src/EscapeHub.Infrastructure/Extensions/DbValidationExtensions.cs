using Microsoft.EntityFrameworkCore;
using EscapeHub.Application.Exceptions;
using EscapeHub.Infrastructure.Data;

namespace EscapeHub.Infrastructure.Extensions;

public static class DbValidationExtensions
{
    public static async Task EnsureCityExistsAsync(this AppDbContext db, int? cityId)
    {
        if (cityId.HasValue && !await db.Cities.AnyAsync(c => c.Id == cityId))
            throw new BusinessException("Select a city from the list.", "cityId");
    }
}
