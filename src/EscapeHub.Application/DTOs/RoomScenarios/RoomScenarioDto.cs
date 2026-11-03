using System.ComponentModel.DataAnnotations;
using EscapeHub.Application.DTOs.Common;

namespace EscapeHub.Application.DTOs.RoomScenarios;

public class RoomScenarioDto
{
    public int Id { get; set; }
    public int RoomId { get; set; }
    public string RoomName { get; set; } = string.Empty;
    public string? RoomImageUrl { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Story { get; set; } = string.Empty;
    public int? DifficultyOverrideId { get; set; }
    public string? DifficultyName { get; set; }
    public string? HintPolicy { get; set; }
    public bool IsActive { get; set; }
}

public class RoomScenarioQuery : SortedQuery
{
    public int? RoomId { get; set; }
    public bool? IsActive { get; set; }
}

public class SaveRoomScenarioRequest
{
    [Range(1, int.MaxValue, ErrorMessage = "Select a room.")]
    public int RoomId { get; set; }

    [Required(ErrorMessage = "Name is required.")]
    [StringLength(200, ErrorMessage = "Name can have at most 200 characters.")]
    public string Name { get; set; } = string.Empty;

    [Required(ErrorMessage = "Story is required.")]
    [StringLength(2000, ErrorMessage = "Story can have at most 2000 characters.")]
    public string Story { get; set; } = string.Empty;

    public int? DifficultyOverrideId { get; set; }

    [StringLength(500, ErrorMessage = "Hint policy can have at most 500 characters.")]
    public string? HintPolicy { get; set; }

    public bool IsActive { get; set; } = true;
}
