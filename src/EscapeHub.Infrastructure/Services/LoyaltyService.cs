using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using EscapeHub.Application.Contracts.Events;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.DTOs.Loyalty;
using EscapeHub.Application.Exceptions;
using EscapeHub.Application.Interfaces;
using EscapeHub.Domain.Entities;
using EscapeHub.Domain.Enums;
using EscapeHub.Infrastructure.Data;
using EscapeHub.Infrastructure.Extensions;
using EscapeHub.Infrastructure.Identity;

namespace EscapeHub.Infrastructure.Services;

public class LoyaltyService
{
    private readonly AppDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly IEventPublisher _events;
    private readonly BusinessClock _clock;
    private readonly ILogger<LoyaltyService> _logger;

    public LoyaltyService(AppDbContext db, ICurrentUser currentUser, IEventPublisher events, BusinessClock clock, ILogger<LoyaltyService> logger)
    {
        _db = db;
        _currentUser = currentUser;
        _events = events;
        _clock = clock;
        _logger = logger;
    }

    public async Task<PagedResult<LoyaltyRewardDto>> GetRewardsAsync(RewardQuery query)
    {
        var rewards = _db.LoyaltyRewards.AsNoTracking().Where(r => !r.IsDeleted);
        if (_currentUser.IsClient) rewards = rewards.Where(r => r.IsActive);
        else if (query.IsActive.HasValue) rewards = rewards.Where(r => r.IsActive == query.IsActive);
        if (query.RewardTypeId.HasValue) rewards = rewards.Where(r => r.RewardTypeId == query.RewardTypeId);
        if (query.Search.Like() is { } like)
            rewards = rewards.Where(r => EF.Functions.Like(r.Name, like) || EF.Functions.Like(r.Description, like));

        var sorted = query.IsNewestFirst() ? rewards.NewestFirst() : rewards.OrderBy(r => r.PointsCost).ThenBy(r => r.Name);
        var page = await sorted.Select(ToRewardDto).ToPagedResultAsync(query);
        page.Items.ForEach(ApplyVisibility);
        return page;
    }

    public async Task<LoyaltyRewardDto> GetRewardAsync(int id)
    {
        var reward = await _db.LoyaltyRewards.AsNoTracking()
            .Where(r => r.Id == id && !r.IsDeleted && (r.IsActive || !_currentUser.IsClient))
            .Select(ToRewardDto)
            .FirstOrDefaultAsync()
            ?? throw new NotFoundException("Reward not found.");
        ApplyVisibility(reward);
        return reward;
    }

    public async Task<LoyaltyRewardDto> CreateRewardAsync(SaveLoyaltyRewardRequest request)
    {
        await ValidateRewardAsync(request);
        var reward = new LoyaltyReward();
        Apply(reward, request);
        _db.LoyaltyRewards.Add(reward);
        await _db.SaveChangesAsync();
        _logger.LogInformation("Reward {RewardId} created by {UserId}", reward.Id, _currentUser.Id);
        return await GetRewardAsync(reward.Id);
    }

    public async Task<LoyaltyRewardDto> UpdateRewardAsync(int id, SaveLoyaltyRewardRequest request)
    {
        var reward = await LoadRewardAsync(id);
        await ValidateRewardAsync(request);
        Apply(reward, request);
        await _db.SaveChangesAsync();
        return await GetRewardAsync(id);
    }

    public async Task DeleteRewardAsync(int id)
    {
        var reward = await LoadRewardAsync(id);
        var unused = await _db.RewardRedemptions.CountAsync(r => r.LoyaltyRewardId == id && !r.IsUsed);
        if (unused > 0)
            throw new ConflictException($"This reward has {unused.Counted("unused voucher", "unused vouchers")} and cannot be deleted. Deactivate it instead.");

        reward.IsDeleted = true;
        reward.IsActive = false;
        await _db.SaveChangesAsync();
        _logger.LogInformation("Reward {RewardId} deleted by {UserId}", id, _currentUser.Id);
    }

    public async Task<LoyaltyBalanceDto> GetBalanceAsync(int clientId)
    {
        var totals = await _db.LoyaltyTransactions.AsNoTracking()
            .Where(t => t.ClientId == clientId)
            .GroupBy(_ => 1)
            .OrderBy(g => g.Key)
            .Select(g => new LoyaltyBalanceDto
            {
                Balance = g.Sum(t => t.Points),
                EarnedTotal = g.Where(t => t.TransactionType == TransactionType.Earned).Sum(t => t.Points),
                RedeemedTotal = -g.Where(t => t.TransactionType == TransactionType.Redeemed).Sum(t => t.Points)
            })
            .FirstOrDefaultAsync();
        return totals ?? new LoyaltyBalanceDto();
    }

    public Task<PagedResult<LoyaltyTransactionDto>> GetClientTransactionsAsync(int clientId, TransactionQuery query)
    {
        query.ClientId = clientId;
        return GetTransactionsAsync(query);
    }

    public Task<PagedResult<LoyaltyTransactionDto>> GetTransactionsAsync(TransactionQuery query)
    {
        var transactions = _db.LoyaltyTransactions.AsNoTracking();
        if (_currentUser.IsClient) transactions = transactions.Where(t => t.ClientId == _currentUser.Id);
        else if (query.ClientId.HasValue) transactions = transactions.Where(t => t.ClientId == query.ClientId);
        if (query.Type != null)
        {
            var type = Enum.Parse<TransactionType>(query.Type);
            transactions = transactions.Where(t => t.TransactionType == type);
        }
        if (query.From.HasValue) transactions = transactions.Where(t => t.CreatedAt >= _clock.UtcDayStart(query.From.Value));
        if (query.To.HasValue) transactions = transactions.Where(t => t.CreatedAt < _clock.UtcDayEnd(query.To.Value));
        if (query.Search.Like() is { } like)
            transactions = transactions.Where(t => EF.Functions.Like(t.Client.FirstName + " " + t.Client.LastName, like) ||
                                                   EF.Functions.Like(t.Description ?? string.Empty, like));

        return transactions.OrderByDescending(t => t.CreatedAt).ThenByDescending(t => t.Id)
            .Select(t => new TransactionRow
            {
                Id = t.Id,
                ClientId = t.ClientId,
                ClientName = t.Client.FirstName + " " + t.Client.LastName,
                ClientPictureUrl = t.Client.ProfilePictureUrl,
                Points = t.Points,
                Type = t.TransactionType,
                Description = t.Description,
                BookingId = t.BookingId,
                RoomName = t.Booking != null ? t.Booking.Schedule.Room.Name : null,
                RoomImageUrl = t.Booking != null ? t.Booking.Schedule.Room.ImageUrl : null,
                CreatedAt = t.CreatedAt
            })
            .ToPagedResultAsync(query, ToTransactionDto);
    }

    public Task<PagedResult<RewardRedemptionDto>> GetRedemptionsAsync(RedemptionQuery query)
    {
        var redemptions = _db.RewardRedemptions.AsNoTracking();
        if (query.ClientId.HasValue) redemptions = redemptions.Where(r => r.ClientId == query.ClientId);
        if (query.RewardId.HasValue) redemptions = redemptions.Where(r => r.LoyaltyRewardId == query.RewardId);
        if (query.From.HasValue) redemptions = redemptions.Where(r => r.CreatedAt >= _clock.UtcDayStart(query.From.Value));
        if (query.To.HasValue) redemptions = redemptions.Where(r => r.CreatedAt < _clock.UtcDayEnd(query.To.Value));
        return PageRedemptions(redemptions, query.IsUsed, query);
    }

    public Task<PagedResult<RewardRedemptionDto>> GetMyRedemptionsAsync(MyRedemptionsQuery query) =>
        PageRedemptions(_db.RewardRedemptions.AsNoTracking().Where(r => r.ClientId == _currentUser.Id), query.IsUsed, query);

    public async Task<RewardRedemptionDto> RedeemAsync(int rewardId)
    {
        try
        {
            return await TryRedeemAsync(rewardId);
        }
        catch (Exception ex) when (ex.HasSqlError(SqlErrors.Deadlock))
        {
            _logger.LogWarning("Redeem of reward {RewardId} by client {ClientId} hit a deadlock. Trying again", rewardId, _currentUser.Id);
            _db.ChangeTracker.Clear();
            return await TryRedeemAsync(rewardId);
        }
    }

    private async Task<RewardRedemptionDto> TryRedeemAsync(int rewardId)
    {
        await using var transaction = await _db.Database.BeginTransactionAsync();
        await _db.Database.ExecuteSqlAsync($"SELECT Id FROM AspNetUsers WITH (UPDLOCK, ROWLOCK) WHERE Id = {_currentUser.Id}");
        var reward = await _db.LoyaltyRewards.Include(r => r.RewardType).FirstOrDefaultAsync(r => r.Id == rewardId && r.IsActive && !r.IsDeleted)
            ?? throw new NotFoundException("Reward not found.");

        var balance = await _db.LoyaltyTransactions.Where(t => t.ClientId == _currentUser.Id).SumAsync(t => t.Points);
        if (balance < reward.PointsCost)
            throw new BusinessException($"You need {reward.PointsCost} points for this reward. Your balance is {balance} points.", "points");

        var redemption = new RewardRedemption
        {
            ClientId = _currentUser.Id,
            LoyaltyRewardId = reward.Id,
            PointsSpent = reward.PointsCost,
            Value = reward.Value,
            IsPercentage = reward.RewardType.IsPercentage,
            Code = SecureCodes.Voucher()
        };
        _db.LoyaltyTransactions.Add(new LoyaltyTransaction
        {
            ClientId = _currentUser.Id,
            Points = -reward.PointsCost,
            TransactionType = TransactionType.Redeemed,
            RewardRedemption = redemption,
            Description = $"Redeemed {reward.Name}"
        });
        await _db.SaveChangesAsync();
        await transaction.CommitAsync();

        _logger.LogInformation("Client {ClientId} redeemed reward {RewardId} as redemption {RedemptionId}",
            _currentUser.Id, reward.Id, redemption.Id);
        _events.Publish(EventQueues.RewardRedeemed, new RewardRedeemedEvent(redemption.Id, _currentUser.Id));
        return await _db.RewardRedemptions.AsNoTracking().Where(r => r.Id == redemption.Id).Select(ToRedemptionDto).FirstAsync();
    }

    private static Task<PagedResult<RewardRedemptionDto>> PageRedemptions(IQueryable<RewardRedemption> redemptions, bool? isUsed, PaginationQuery query)
    {
        if (isUsed.HasValue) redemptions = redemptions.Where(r => r.IsUsed == isUsed);
        if (query.Search.Like() is { } like)
            redemptions = redemptions.Where(r => EF.Functions.Like(r.Code, like) || EF.Functions.Like(r.LoyaltyReward.Name, like) ||
                                                 EF.Functions.Like(r.Client.FirstName + " " + r.Client.LastName, like));
        return redemptions.OrderByDescending(r => r.CreatedAt).ThenByDescending(r => r.Id).Select(ToRedemptionDto).ToPagedResultAsync(query);
    }

    private async Task<LoyaltyReward> LoadRewardAsync(int id) =>
        await _db.LoyaltyRewards.FirstOrDefaultAsync(r => r.Id == id && !r.IsDeleted)
        ?? throw new NotFoundException("Reward not found.");

    private async Task ValidateRewardAsync(SaveLoyaltyRewardRequest request)
    {
        var type = await _db.RewardTypes.AsNoTracking().FirstOrDefaultAsync(t => t.Id == request.RewardTypeId)
            ?? throw new BusinessException("Select a reward type from the list.", "rewardTypeId");
        if (type.IsPercentage && request.Value > 100)
            throw new BusinessException("A percentage reward cannot be more than 100.", "value");
    }

    private static void Apply(LoyaltyReward reward, SaveLoyaltyRewardRequest request)
    {
        reward.Name = request.Name.Trim();
        reward.Description = request.Description.Trim();
        reward.PointsCost = request.PointsCost;
        reward.RewardTypeId = request.RewardTypeId;
        reward.Value = request.Value;
        reward.IsActive = request.IsActive;
    }

    private void ApplyVisibility(LoyaltyRewardDto reward)
    {
        if (_currentUser.IsClient)
            reward.CanDelete = null;
        else if (reward.CanDelete == false)
            reward.DeleteBlockedReason = "This reward has unused vouchers and cannot be deleted. Deactivate it instead.";
    }

    private static LoyaltyTransactionDto ToTransactionDto(TransactionRow row) => new()
    {
        Id = row.Id,
        ClientId = row.ClientId,
        ClientName = row.ClientName,
        ClientPictureUrl = row.ClientPictureUrl,
        Points = row.Points,
        TransactionType = row.Type.ToString(),
        Description = row.Description,
        BookingId = row.BookingId,
        RoomName = row.RoomName,
        RoomImageUrl = row.RoomImageUrl,
        CreatedAt = row.CreatedAt
    };

    private static readonly Expression<Func<LoyaltyReward, LoyaltyRewardDto>> ToRewardDto = r => new LoyaltyRewardDto
    {
        Id = r.Id,
        Name = r.Name,
        Description = r.Description,
        PointsCost = r.PointsCost,
        RewardTypeId = r.RewardTypeId,
        RewardTypeName = r.RewardType.Name,
        IsPercentage = r.RewardType.IsPercentage,
        Value = r.Value,
        IsActive = r.IsActive,
        RedemptionCount = r.RewardRedemptions.Count(),
        CanDelete = !r.RewardRedemptions.Any(x => !x.IsUsed)
    };

    private static readonly Expression<Func<RewardRedemption, RewardRedemptionDto>> ToRedemptionDto = r => new RewardRedemptionDto
    {
        Id = r.Id,
        ClientId = r.ClientId,
        ClientName = r.Client.FirstName + " " + r.Client.LastName,
        ClientPictureUrl = r.Client.ProfilePictureUrl,
        RewardId = r.LoyaltyRewardId,
        RewardName = r.LoyaltyReward.Name,
        RewardTypeName = r.LoyaltyReward.RewardType.Name,
        IsPercentage = r.IsPercentage,
        Value = r.Value,
        PointsSpent = r.PointsSpent,
        Code = r.Code,
        IsUsed = r.IsUsed,
        UsedAt = r.UsedAt,
        BookingId = r.BookingId,
        RedeemedAt = r.CreatedAt
    };

    private class TransactionRow
    {
        public int Id { get; init; }
        public int ClientId { get; init; }
        public string ClientName { get; init; } = string.Empty;
        public string? ClientPictureUrl { get; init; }
        public int Points { get; init; }
        public TransactionType Type { get; init; }
        public string? Description { get; init; }
        public int? BookingId { get; init; }
        public string? RoomName { get; init; }
        public string? RoomImageUrl { get; init; }
        public DateTime CreatedAt { get; init; }
    }
}
