using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using EscapeHub.Application.DTOs.Bookings;
using EscapeHub.Application.DTOs.Payments;
using EscapeHub.Domain.Constants;
using EscapeHub.Infrastructure.Services;

namespace EscapeHub.Api.Controllers;

[ApiController]
[Authorize]
public class PaymentsController : ControllerBase
{
    private readonly PaymentService _payments;

    public PaymentsController(PaymentService payments) => _payments = payments;

    [HttpPost("api/bookings/{id:int}/payment")]
    [Authorize(Roles = Roles.Client)]
    public Task<PaymentStartDto> Start(int id) => _payments.StartAsync(id);

    [HttpPost("api/bookings/{id:int}/payment/verify")]
    public Task<BookingDto> Verify(int id) => _payments.VerifyAsync(id);
}
