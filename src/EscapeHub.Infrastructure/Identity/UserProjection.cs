using System.Linq.Expressions;
using EscapeHub.Application.DTOs.Users;
using EscapeHub.Domain.Entities;
using EscapeHub.Infrastructure.Data;

namespace EscapeHub.Infrastructure.Identity;

public static class UserProjection
{
    public static Expression<Func<ApplicationUser, UserDto>> ToDto(AppDbContext db) => u => new UserDto
    {
        Id = u.Id,
        Username = u.UserName!,
        Email = u.Email!,
        FirstName = u.FirstName,
        LastName = u.LastName,
        Phone = u.PhoneNumber,
        ProfilePictureUrl = u.ProfilePictureUrl,
        IsActive = u.IsActive,
        Role = db.UserRoles.Where(ur => ur.UserId == u.Id)
            .Join(db.Roles, ur => ur.RoleId, r => r.Id, (ur, r) => r.Name!)
            .FirstOrDefault() ?? string.Empty,
        CityId = u.CityId,
        CityName = u.City != null ? u.City.Name : null,
        CountryId = u.City != null ? u.City.CountryId : null,
        CountryName = u.City != null ? u.City.Country.Name : null,
        CreatedAt = u.CreatedAt
    };

    public static IQueryable<ApplicationUser> InRoles(this IQueryable<ApplicationUser> users, AppDbContext db, params string[] roles) =>
        users.Where(u => db.UserRoles.Any(ur => ur.UserId == u.Id &&
            db.Roles.Any(r => r.Id == ur.RoleId && roles.Contains(r.Name!))));
}
