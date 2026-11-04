using Microsoft.EntityFrameworkCore;
using EscapeHub.Application.Contracts.Events;
using EscapeHub.Application.DTOs.Bookings;
using EscapeHub.Application.DTOs.Payments;
using EscapeHub.Application.Exceptions;
using EscapeHub.Application.Interfaces;
using EscapeHub.Domain.Entities;
using EscapeHub.Domain.Enums;
using EscapeHub.Infrastructure.Configuration;
using EscapeHub.Infrastructure.Data;
using EscapeHub.Infrastructure.Extensions;

namespace EscapeHub.Infrastructure.Services;

public class PaymentService
{
    private const int ProcessingAttempts = 5;

    private readonly AppDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly RoomAccess _access;
    private readonly BookingService _bookings;
    private readonly PolarClient _polar;
    private readonly PolarOptions _options;
    private readonly IEventPublisher _events;
    private readonly BusinessClock _clock;

    public PaymentService(AppDbContext db, ICurrentUser currentUser, RoomAccess access, BookingService bookings,
        PolarClient polar, PolarOptions options, IEventPublisher events, BusinessClock clock)
    {
        _db = db;
        _currentUser = currentUser;
        _access = access;
        _bookings = bookings;
        _polar = polar;
        _options = options;
        _events = events;
        _clock = clock;
    }

    public async Task<PaymentStartDto> StartAsync(int bookingId)
    {
        var booking = await LoadAsync(bookingId);
        if (booking.ClientId != _currentUser.Id)
            throw new ForbiddenException("You can access only your own bookings.");
        EnsurePayable(booking);

        if (booking.Payments.FirstOrDefault(p => p.Status == PaymentStatus.Open) is { } open)
        {
            await RefreshAsync(open);
            EnsurePayable(booking);
            if (open.Status == PaymentStatus.Open)
                return ToStart(open);
        }

        return ToStart(await CreateAsync(booking));
    }

    public async Task<BookingDto> VerifyAsync(int bookingId)
    {
        var booking = await LoadAsync(bookingId);
        _access.EnsureCanAccessBooking(booking.ClientId, booking.Schedule.Room.ManagerId);
        if (booking.Payments.Where(p => p.Status == PaymentStatus.Open).MaxBy(p => p.Id) is { } open)
            await RefreshAsync(open);
        return await _bookings.GetByIdAsync(bookingId);
    }

    public async Task<bool> VerifyCheckoutAsync(string checkoutId)
    {
        var payment = await _db.Payments.FirstOrDefaultAsync(p => p.CheckoutId == checkoutId)
            ?? throw new NotFoundException("Payment not found.");
        if (payment.Status == PaymentStatus.Open)
            await RefreshAsync(payment);
        return payment.Status == PaymentStatus.Succeeded;
    }

    private async Task<Booking> LoadAsync(int bookingId) =>
        await _db.Bookings
            .Include(b => b.Schedule).ThenInclude(s => s.Room)
            .Include(b => b.Payments)
            .FirstOrDefaultAsync(b => b.Id == bookingId)
        ?? throw new NotFoundException("Booking not found.");

    private void EnsurePayable(Booking booking)
    {
        if (PaymentRules.Problem(booking, _clock.Now) is not { } problem) return;
        throw PaymentRules.IsPaid(booking) ? new ConflictException(problem) : new BusinessException(problem);
    }

    private PaymentStartDto ToStart(Payment payment) => new(payment.Id, payment.CheckoutUrl, _options.SuccessUrl);

    private async Task<Payment> CreateAsync(Booking booking)
    {
        var checkout = await _polar.CreateCheckoutAsync(booking.Id, booking.ClientId, booking.TotalPrice);
        var payment = new Payment
        {
            BookingId = booking.Id,
            CheckoutId = checkout.Id,
            CheckoutUrl = checkout.Url,
            Status = PaymentStatus.Open,
            Amount = booking.TotalPrice
        };
        _db.Payments.Add(payment);
        try
        {
            await _db.SaveChangesAsync();
        }
        catch (DbUpdateException ex) when (ex.HasSqlError(SqlErrors.UniqueIndexViolation, SqlErrors.UniqueConstraintViolation))
        {
            throw new ConflictException("A payment for this booking is already in progress.");
        }
        return payment;
    }

    private async Task RefreshAsync(Payment payment)
    {
        var checkout = await GetSettledCheckoutAsync(payment.CheckoutId);
        switch (checkout.Status)
        {
            case "succeeded" when Matches(payment, checkout):
                await CompleteAsync(payment);
                break;
            case "expired":
                await CloseAsync(payment, PaymentStatus.Expired);
                break;
            case "failed":
                await CloseAsync(payment, PaymentStatus.Failed);
                break;
        }
    }

    private async Task<PolarCheckout> GetSettledCheckoutAsync(string checkoutId)
    {
        var checkout = await _polar.GetCheckoutAsync(checkoutId);
        for (var attempt = 1; checkout.Status == "confirmed" && attempt < ProcessingAttempts; attempt++)
        {
            await Task.Delay(TimeSpan.FromSeconds(1));
            checkout = await _polar.GetCheckoutAsync(checkoutId);
        }
        return checkout;
    }

    private static bool Matches(Payment payment, PolarCheckout checkout) =>
        checkout.TotalAmount == (long)Math.Round(payment.Amount * 100, MidpointRounding.AwayFromZero) &&
        string.Equals(checkout.Currency, payment.Currency, StringComparison.OrdinalIgnoreCase) &&
        checkout.Metadata?.GetValueOrDefault("booking_id") == payment.BookingId.ToString();

    private async Task CompleteAsync(Payment payment)
    {
        var orderId = await _polar.GetOrderIdAsync(payment.CheckoutId);
        var now = DateTime.UtcNow;
        var changed = await _db.Payments
            .Where(p => p.Id == payment.Id && p.Status != PaymentStatus.Succeeded)
            .ExecuteUpdateAsync(s => s
                .SetProperty(p => p.Status, PaymentStatus.Succeeded)
                .SetProperty(p => p.PaidAt, now)
                .SetProperty(p => p.OrderId, orderId)
                .SetProperty(p => p.UpdatedAt, now));
        await _db.Entry(payment).ReloadAsync();
        if (changed != 1) return;

        var clientId = await _db.Bookings.Where(b => b.Id == payment.BookingId).Select(b => b.ClientId).FirstAsync();
        _events.Publish(EventQueues.PaymentCompleted, new PaymentCompletedEvent(payment.BookingId, clientId, payment.Amount));
    }

    private async Task CloseAsync(Payment payment, PaymentStatus status)
    {
        await _db.Payments
            .Where(p => p.Id == payment.Id && p.Status == PaymentStatus.Open)
            .ExecuteUpdateAsync(s => s
                .SetProperty(p => p.Status, status)
                .SetProperty(p => p.UpdatedAt, DateTime.UtcNow));
        await _db.Entry(payment).ReloadAsync();
    }
}
