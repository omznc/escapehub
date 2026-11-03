using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.DTOs.Reviews;
using EscapeHub.Application.Exceptions;
using EscapeHub.Application.Interfaces;
using EscapeHub.Domain.Entities;
using EscapeHub.Infrastructure.Data;
using EscapeHub.Infrastructure.Extensions;

namespace EscapeHub.Infrastructure.Services;

public class ReviewService
{
    private readonly AppDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly RoomAccess _access;
    private readonly BusinessClock _clock;
    private readonly ILogger<ReviewService> _logger;

    public ReviewService(AppDbContext db, ICurrentUser currentUser, RoomAccess access, BusinessClock clock, ILogger<ReviewService> logger)
    {
        _db = db;
        _currentUser = currentUser;
        _access = access;
        _clock = clock;
        _logger = logger;
    }

    public Task<PagedResult<ReviewDto>> GetAllAsync(ReviewQuery query)
    {
        var reviews = _db.Reviews.AsNoTracking();
        if (_access.ManagerScope is { } managerId) reviews = reviews.Where(r => r.Room.ManagerId == managerId);
        if (!query.IncludeHidden) reviews = reviews.Where(r => !r.IsHidden);
        return Page(Filter(reviews, query), query);
    }

    public Task<PagedResult<ReviewDto>> GetForRoomAsync(int roomId, ReviewQuery query)
    {
        var reviews = _db.Reviews.AsNoTracking().Where(r => r.RoomId == roomId && !r.IsHidden && r.Room.IsActive);
        query.RoomId = null;
        return Page(Filter(reviews, query), query);
    }

    public Task<PagedResult<ReviewDto>> GetMineAsync(MyReviewsQuery query)
    {
        var reviews = _db.Reviews.AsNoTracking().Where(r => r.ClientId == _currentUser.Id);
        if (query.RoomId.HasValue) reviews = reviews.Where(r => r.RoomId == query.RoomId);
        return Page(reviews, query);
    }

    public async Task<ReviewDto> CreateAsync(CreateReviewRequest request)
    {
        if (!await _db.Rooms.AnyAsync(r => r.Id == request.RoomId))
            throw new BusinessException("Select a room from the list.", "roomId");
        if (!await _db.Bookings.AnyAsync(b => b.ClientId == _currentUser.Id && b.Schedule.RoomId == request.RoomId &&
                                              b.BookingStatusId == BookingRules.Completed))
            throw new BusinessException("You can review a room only after you complete a session in it.", "roomId");
        if (await _db.Reviews.AnyAsync(r => r.ClientId == _currentUser.Id && r.RoomId == request.RoomId))
            throw new ConflictException("You have already reviewed this room. Edit your existing review.");

        var review = new Review
        {
            RoomId = request.RoomId,
            ClientId = _currentUser.Id,
            Rating = request.Rating,
            Comment = Clean(request.Comment)
        };
        _db.Reviews.Add(review);
        await _db.SaveChangesAsync();
        _logger.LogInformation("Review {ReviewId} created by client {ClientId} for room {RoomId}", review.Id, _currentUser.Id, review.RoomId);
        return await GetByIdAsync(review.Id);
    }

    public async Task<ReviewDto> UpdateAsync(int id, UpdateReviewRequest request)
    {
        var review = await LoadOwnAsync(id);
        review.Rating = request.Rating;
        review.Comment = Clean(request.Comment);
        await _db.SaveChangesAsync();
        return await GetByIdAsync(id);
    }

    public async Task DeleteAsync(int id)
    {
        var review = await LoadOwnAsync(id);
        review.IsDeleted = true;
        await _db.SaveChangesAsync();
        _logger.LogInformation("Review {ReviewId} deleted by client {ClientId}", id, _currentUser.Id);
    }

    public async Task SetHiddenAsync(int id, bool isHidden)
    {
        var review = await _db.Reviews.Include(r => r.Room).FirstOrDefaultAsync(r => r.Id == id)
            ?? throw new NotFoundException("Review not found.");
        _access.EnsureCanManage(review.Room.ManagerId);
        review.IsHidden = isHidden;
        await _db.SaveChangesAsync();
        _logger.LogInformation("Review {ReviewId} hidden state set to {IsHidden} by {UserId}", id, isHidden, _currentUser.Id);
    }

    private async Task<ReviewDto> GetByIdAsync(int id) =>
        await _db.Reviews.AsNoTracking().Where(r => r.Id == id).Select(ToDto).FirstAsync();

    private async Task<Review> LoadOwnAsync(int id)
    {
        var review = await _db.Reviews.FirstOrDefaultAsync(r => r.Id == id)
            ?? throw new NotFoundException("Review not found.");
        if (review.ClientId != _currentUser.Id)
            throw new ForbiddenException("You can change only your own reviews.");
        return review;
    }

    private IQueryable<Review> Filter(IQueryable<Review> reviews, ReviewQuery query)
    {
        if (query.RoomId.HasValue) reviews = reviews.Where(r => r.RoomId == query.RoomId);
        if (query.ClientId.HasValue) reviews = reviews.Where(r => r.ClientId == query.ClientId);
        if (query.Rating.HasValue) reviews = reviews.Where(r => r.Rating == query.Rating);
        if (query.MinRating.HasValue) reviews = reviews.Where(r => r.Rating >= query.MinRating);
        if (query.From.HasValue) reviews = reviews.Where(r => r.CreatedAt >= _clock.UtcDayStart(query.From.Value));
        if (query.To.HasValue) reviews = reviews.Where(r => r.CreatedAt < _clock.UtcDayEnd(query.To.Value));
        return reviews;
    }

    private async Task<PagedResult<ReviewDto>> Page(IQueryable<Review> reviews, PaginationQuery query)
    {
        if (query.Search.Like() is { } like)
            reviews = reviews.Where(r => EF.Functions.Like(r.Comment ?? string.Empty, like) || EF.Functions.Like(r.Room.Name, like) ||
                                         EF.Functions.Like(r.Client.FirstName + " " + r.Client.LastName, like));
        var page = await reviews.OrderByDescending(r => r.CreatedAt).ThenByDescending(r => r.Id).Select(ToDto).ToPagedResultAsync(query);
        if (_currentUser.IsClient)
            foreach (var review in page.Items.Where(r => r.ClientId != _currentUser.Id))
                review.ClientPictureUrl = null;
        return page;
    }

    private static string? Clean(string? comment) => string.IsNullOrWhiteSpace(comment) ? null : comment.Trim();

    private static readonly Expression<Func<Review, ReviewDto>> ToDto = r => new ReviewDto
    {
        Id = r.Id,
        RoomId = r.RoomId,
        RoomName = r.Room.Name,
        RoomImageUrl = r.Room.ImageUrl,
        ClientId = r.ClientId,
        ClientName = r.Client.FirstName + " " + r.Client.LastName,
        ClientPictureUrl = r.Client.ProfilePictureUrl,
        Rating = r.Rating,
        Comment = r.Comment,
        IsHidden = r.IsHidden,
        CreatedAt = r.CreatedAt,
        UpdatedAt = r.UpdatedAt
    };
}
