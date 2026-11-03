using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using EscapeHub.Application.DTOs.Bookings;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Domain.Constants;
using EscapeHub.Infrastructure.Services;

namespace EscapeHub.Api.Controllers;

[ApiController]
[Route("api/bookings")]
[Authorize]
public class BookingsController : ControllerBase
{
    private readonly BookingService _bookings;
    private readonly BookingWorkflowService _workflow;

    public BookingsController(BookingService bookings, BookingWorkflowService workflow)
    {
        _bookings = bookings;
        _workflow = workflow;
    }

    [HttpGet]
    [Authorize(Roles = Roles.Staff)]
    public Task<PagedResult<BookingListItemDto>> GetAll([FromQuery] BookingQuery query) => _bookings.GetAllAsync(query);

    [HttpGet("me")]
    [Authorize(Roles = Roles.Client)]
    public Task<PagedResult<BookingListItemDto>> GetMine([FromQuery] MyBookingsQuery query) => _bookings.GetMineAsync(query);

    [HttpGet("{id:int}")]
    public Task<BookingDto> Get(int id) => _bookings.GetByIdAsync(id);

    [HttpPost("quote")]
    public Task<BookingQuoteDto> Quote(CreateBookingRequest request) => _bookings.QuoteAsync(request);

    [HttpPost]
    public async Task<ActionResult<BookingDto>> Create(CreateBookingRequest request)
    {
        var booking = await _bookings.CreateAsync(request);
        return CreatedAtAction(nameof(Get), new { id = booking.Id }, booking);
    }

    [HttpPost("{id:int}/confirm")]
    [Authorize(Roles = Roles.Staff)]
    public async Task<BookingDto> Confirm(int id)
    {
        await _workflow.ConfirmAsync(id);
        return await _bookings.GetByIdAsync(id);
    }

    [HttpPost("{id:int}/reject")]
    [Authorize(Roles = Roles.Staff)]
    public async Task<BookingDto> Reject(int id, RejectBookingRequest request)
    {
        await _workflow.RejectAsync(id, request);
        return await _bookings.GetByIdAsync(id);
    }

    [HttpPost("{id:int}/cancel")]
    public async Task<BookingDto> Cancel(int id, ReasonRequest request)
    {
        await _workflow.CancelAsync(id, request);
        return await _bookings.GetByIdAsync(id);
    }

    [HttpPost("{id:int}/complete")]
    [Authorize(Roles = Roles.Staff)]
    public async Task<BookingDto> Complete(int id, [FromBody(EmptyBodyBehavior = EmptyBodyBehavior.Allow)] CompleteBookingRequest? request)
    {
        await _workflow.CompleteAsync(id, request ?? new CompleteBookingRequest());
        return await _bookings.GetByIdAsync(id);
    }

    [HttpPost("{id:int}/no-show")]
    [Authorize(Roles = Roles.Staff)]
    public async Task<BookingDto> NoShow(int id)
    {
        await _workflow.MarkNoShowAsync(id);
        return await _bookings.GetByIdAsync(id);
    }

    [HttpPost("{id:int}/result")]
    [Authorize(Roles = Roles.Staff)]
    public async Task<BookingDto> RecordResult(int id, SaveRoomResultRequest request)
    {
        await _workflow.RecordResultAsync(id, request);
        return await _bookings.GetByIdAsync(id);
    }

    [HttpPut("{id:int}/result")]
    [Authorize(Roles = Roles.Staff)]
    public async Task<BookingDto> UpdateResult(int id, SaveRoomResultRequest request)
    {
        await _workflow.UpdateResultAsync(id, request);
        return await _bookings.GetByIdAsync(id);
    }
}
