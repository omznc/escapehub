using System.ComponentModel.DataAnnotations;
using EscapeHub.Application.DTOs.Common;

namespace EscapeHub.Application.DTOs.Reference;

public class ReferenceDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int UsageCount { get; set; }
    public bool CanDelete { get; set; }
    public string? DeleteBlockedReason { get; set; }
}

public class CityDto : ReferenceDto
{
    public int CountryId { get; set; }
    public string CountryName { get; set; } = string.Empty;
}

public class DifficultyLevelDto : ReferenceDto
{
    public int Value { get; set; }
}

public class DiscountTypeDto : ReferenceDto
{
    public bool IsPercentage { get; set; }
}

public class ReferenceRequest
{
    [Required(ErrorMessage = "Name is required.")]
    [StringLength(100, ErrorMessage = "Name can have at most 100 characters.")]
    public string Name { get; set; } = string.Empty;
}

public class CityRequest : ReferenceRequest
{
    [Range(1, int.MaxValue, ErrorMessage = "Select a country.")]
    public int CountryId { get; set; }
}

public class DifficultyLevelRequest : ReferenceRequest
{
    [Range(1, 10, ErrorMessage = "Difficulty value must be between 1 and 10.")]
    public int Value { get; set; }
}

public class DiscountTypeRequest : ReferenceRequest
{
    public bool IsPercentage { get; set; }
}

public class CityQuery : SortedQuery
{
    public int? CountryId { get; set; }
}
