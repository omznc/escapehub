using System.ComponentModel.DataAnnotations;
using EscapeHub.Application.DTOs.Common;

namespace EscapeHub.Application.DTOs.Reviews;

public class ReviewDto
{
    public int Id { get; set; }
    public int RoomId { get; set; }
    public string RoomName { get; set; } = string.Empty;
    public string? RoomImageUrl { get; set; }
    public int ClientId { get; set; }
    public string ClientName { get; set; } = string.Empty;
    public string? ClientPictureUrl { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public bool IsHidden { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class ReviewQuery : PaginationQuery
{
    public int? RoomId { get; set; }
    public int? ClientId { get; set; }

    [Range(1, 5, ErrorMessage = "Rating must be between 1 and 5.")]
    public int? Rating { get; set; }

    [Range(1, 5, ErrorMessage = "Minimum rating must be between 1 and 5.")]
    public int? MinRating { get; set; }

    [DateLimit]
    public DateTime? From { get; set; }

    [DateLimit]
    public DateTime? To { get; set; }

    public bool IncludeHidden { get; set; } = true;
}

public class MyReviewsQuery : PaginationQuery
{
    public int? RoomId { get; set; }
}

public class CreateReviewRequest
{
    [Range(1, int.MaxValue, ErrorMessage = "Select a room.")]
    public int RoomId { get; set; }

    [Range(1, 5, ErrorMessage = "Rating must be between 1 and 5.")]
    public int Rating { get; set; }

    [StringLength(2000, ErrorMessage = "Comment can have at most 2000 characters.")]
    public string? Comment { get; set; }
}

public class UpdateReviewRequest
{
    [Range(1, 5, ErrorMessage = "Rating must be between 1 and 5.")]
    public int Rating { get; set; }

    [StringLength(2000, ErrorMessage = "Comment can have at most 2000 characters.")]
    public string? Comment { get; set; }
}
