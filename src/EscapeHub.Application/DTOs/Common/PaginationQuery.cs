using System.ComponentModel.DataAnnotations;

namespace EscapeHub.Application.DTOs.Common;

public class PaginationQuery
{
    public const int MaxPageSize = 100;
    public const int MaxPage = 100000;

    [Range(1, MaxPage, ErrorMessage = "Page must be between 1 and 100000.")]
    public int Page { get; set; } = 1;

    [Range(1, MaxPageSize, ErrorMessage = "Page size must be between 1 and 100.")]
    public int PageSize { get; set; } = 20;

    [StringLength(100, ErrorMessage = "Search text can have at most 100 characters.")]
    public string? Search { get; set; }

    public int Skip() => (Page - 1) * PageSize;
}

public static class ListSortOptions
{
    public const string Newest = "newest";
}

public class SortedQuery : PaginationQuery
{
    [RegularExpression("^" + ListSortOptions.Newest + "$", ErrorMessage = "Sort must be: newest.")]
    public string? SortBy { get; set; }

    public bool IsNewestFirst() => SortBy == ListSortOptions.Newest;
}
