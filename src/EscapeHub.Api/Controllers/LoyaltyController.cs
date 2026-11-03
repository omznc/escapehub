using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.DTOs.Loyalty;
using EscapeHub.Application.Interfaces;
using EscapeHub.Domain.Constants;
using EscapeHub.Infrastructure.Services;

namespace EscapeHub.Api.Controllers;

[ApiController]
[Route("api/loyalty")]
[Authorize]
public class LoyaltyController : ControllerBase
{
    private readonly LoyaltyService _loyalty;
    private readonly ICurrentUser _currentUser;

    public LoyaltyController(LoyaltyService loyalty, ICurrentUser currentUser)
    {
        _loyalty = loyalty;
        _currentUser = currentUser;
    }

    [HttpGet("rewards")]
    public Task<PagedResult<LoyaltyRewardDto>> GetRewards([FromQuery] RewardQuery query) => _loyalty.GetRewardsAsync(query);

    [HttpGet("rewards/{id:int}")]
    public Task<LoyaltyRewardDto> GetReward(int id) => _loyalty.GetRewardAsync(id);

    [HttpPost("rewards")]
    [Authorize(Roles = Roles.Administrator)]
    public async Task<ActionResult<LoyaltyRewardDto>> CreateReward(SaveLoyaltyRewardRequest request)
    {
        var reward = await _loyalty.CreateRewardAsync(request);
        return CreatedAtAction(nameof(GetReward), new { id = reward.Id }, reward);
    }

    [HttpPut("rewards/{id:int}")]
    [Authorize(Roles = Roles.Administrator)]
    public Task<LoyaltyRewardDto> UpdateReward(int id, SaveLoyaltyRewardRequest request) => _loyalty.UpdateRewardAsync(id, request);

    [HttpDelete("rewards/{id:int}")]
    [Authorize(Roles = Roles.Administrator)]
    public async Task<IActionResult> DeleteReward(int id)
    {
        await _loyalty.DeleteRewardAsync(id);
        return NoContent();
    }

    [HttpPost("rewards/{id:int}/redeem")]
    [Authorize(Roles = Roles.Client)]
    public async Task<ActionResult<RewardRedemptionDto>> Redeem(int id) =>
        StatusCode(StatusCodes.Status201Created, await _loyalty.RedeemAsync(id));

    [HttpGet("me/balance")]
    [Authorize(Roles = Roles.Client)]
    public Task<LoyaltyBalanceDto> GetMyBalance() => _loyalty.GetBalanceAsync(_currentUser.Id);

    [HttpGet("me/transactions")]
    [Authorize(Roles = Roles.Client)]
    public Task<PagedResult<LoyaltyTransactionDto>> GetMyTransactions([FromQuery] TransactionQuery query) => _loyalty.GetTransactionsAsync(query);

    [HttpGet("me/redemptions")]
    [Authorize(Roles = Roles.Client)]
    public Task<PagedResult<RewardRedemptionDto>> GetMyRedemptions([FromQuery] MyRedemptionsQuery query) => _loyalty.GetMyRedemptionsAsync(query);

    [HttpGet("transactions")]
    [Authorize(Roles = Roles.Administrator)]
    public Task<PagedResult<LoyaltyTransactionDto>> GetTransactions([FromQuery] TransactionQuery query) => _loyalty.GetTransactionsAsync(query);

    [HttpGet("redemptions")]
    [Authorize(Roles = Roles.Administrator)]
    public Task<PagedResult<RewardRedemptionDto>> GetRedemptions([FromQuery] RedemptionQuery query) => _loyalty.GetRedemptionsAsync(query);
}
