using Microsoft.EntityFrameworkCore;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Domain.Entities;

namespace EscapeHub.Infrastructure.Extensions;

public static class QueryableExtensions
{
    public static async Task<PagedResult<T>> ToPagedResultAsync<T>(this IQueryable<T> query, PaginationQuery paging)
    {
        var total = await query.CountAsync();
        var items = await query.Skip(paging.Skip()).Take(paging.PageSize).ToListAsync();
        return new PagedResult<T> { Items = items, TotalCount = total, Page = paging.Page, PageSize = paging.PageSize };
    }

    public static async Task<PagedResult<TOut>> ToPagedResultAsync<TIn, TOut>(this IQueryable<TIn> query, PaginationQuery paging, Func<TIn, TOut> map)
    {
        var total = await query.CountAsync();
        var items = await query.Skip(paging.Skip()).Take(paging.PageSize).ToListAsync();
        return new PagedResult<TOut> { Items = items.Select(map).ToList(), TotalCount = total, Page = paging.Page, PageSize = paging.PageSize };
    }

    public static IOrderedQueryable<T> NewestFirst<T>(this IQueryable<T> query) where T : BaseEntity =>
        query.OrderByDescending(e => e.CreatedAt).ThenByDescending(e => e.Id);

    public static string? Like(this string? search) =>
        string.IsNullOrWhiteSpace(search)
            ? null
            : $"%{search.Trim().Replace("[", "[[]").Replace("%", "[%]").Replace("_", "[_]")}%";
}
