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

    [HttpGet("api/payments/return")]
    [AllowAnonymous]
    public async Task<ContentResult> Return([FromQuery(Name = "checkout_id")] string checkoutId)
    {
        var message = await _payments.VerifyCheckoutAsync(checkoutId)
            ? "Payment received. You can go back to the EscapeHub app."
            : "Payment is processing. You can go back to the EscapeHub app.";
        return Content($"<!DOCTYPE html><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"><p style=\"font-size:1.5em;padding:1em\">{message}</p>", "text/html");
    }
}
