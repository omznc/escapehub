using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EscapeHub.Application.DTOs.Bookings;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.DTOs.Loyalty;
using EscapeHub.Application.DTOs.Users;
using EscapeHub.Domain.Constants;
using EscapeHub.Infrastructure.Services;

namespace EscapeHub.Api.Controllers;

[ApiController]
[Route("api/clients")]
[Authorize(Roles = Roles.Staff)]
public class ClientsController : ControllerBase
{
    private readonly UserService _users;
    private readonly BookingService _bookings;
    private readonly LoyaltyService _loyalty;

    public ClientsController(UserService users, BookingService bookings, LoyaltyService loyalty)
    {
        _users = users;
        _bookings = bookings;
        _loyalty = loyalty;
    }

    [HttpGet]
    public Task<PagedResult<UserDto>> GetAll([FromQuery] UserQuery query) => _users.GetClientsAsync(query);

    [HttpGet("{id:int}")]
    public Task<UserDto> Get(int id) => _users.GetByIdAsync(id, Roles.Client);

    [HttpGet("{id:int}/bookings")]
    public Task<PagedResult<BookingListItemDto>> GetBookings(int id, [FromQuery] BookingQuery query)
    {
        query.ClientId = id;
        return _bookings.GetAllAsync(query);
    }

    [HttpGet("{id:int}/loyalty")]
    public Task<LoyaltyBalanceDto> GetBalance(int id) => _loyalty.GetBalanceAsync(id);

    [HttpGet("{id:int}/transactions")]
    public Task<PagedResult<LoyaltyTransactionDto>> GetTransactions(int id, [FromQuery] TransactionQuery query) =>
        _loyalty.GetClientTransactionsAsync(id, query);
}
