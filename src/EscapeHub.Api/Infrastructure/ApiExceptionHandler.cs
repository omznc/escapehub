using Microsoft.AspNetCore.Diagnostics;
using EscapeHub.Application.DTOs.Common;
using EscapeHub.Application.Exceptions;
using EscapeHub.Infrastructure.Extensions;

namespace EscapeHub.Api.Infrastructure;

public class ApiExceptionHandler : IExceptionHandler
{
    private readonly ILogger<ApiExceptionHandler> _logger;

    public ApiExceptionHandler(ILogger<ApiExceptionHandler> logger) => _logger = logger;

    public async ValueTask<bool> TryHandleAsync(HttpContext context, Exception exception, CancellationToken cancellationToken)
    {
        var (status, body) = Map(exception);
        if (status == StatusCodes.Status500InternalServerError)
            _logger.LogError(exception, "Unhandled error on {Method} {Path}", context.Request.Method, context.Request.Path);
        else if (exception.HasSqlError(SqlErrors.ConstraintViolation, SqlErrors.Deadlock))
            _logger.LogWarning(exception, "Request {Method} {Path} failed with {Status}", context.Request.Method, context.Request.Path, status);
        else
            _logger.LogInformation("Request {Method} {Path} failed with {Status}: {Message}", context.Request.Method, context.Request.Path, status, exception.Message);

        context.Response.StatusCode = status;
        await context.Response.WriteAsJsonAsync(body, cancellationToken);
        return true;
    }

    private static (int Status, ErrorResponse Body) Map(Exception exception) => exception switch
    {
        BusinessException e => (StatusCodes.Status400BadRequest, new ErrorResponse { Message = e.Message, Errors = e.Errors }),
        NotFoundException e => (StatusCodes.Status404NotFound, ErrorResponse.From(e.Message)),
        ForbiddenException e => (StatusCodes.Status403Forbidden, ErrorResponse.From(e.Message)),
        ConflictException e => (StatusCodes.Status409Conflict, new ErrorResponse { Message = e.Message, Errors = e.Errors }),
        AuthenticationFailedException e => (StatusCodes.Status401Unauthorized, ErrorResponse.From(e.Message)),
        _ when exception.HasSqlError(SqlErrors.UniqueIndexViolation, SqlErrors.UniqueConstraintViolation) =>
            (StatusCodes.Status409Conflict, ErrorResponse.From("This record conflicts with an existing record. Refresh the data and try again.")),
        _ when exception.IsForeignKeyConflict() =>
            (StatusCodes.Status409Conflict, ErrorResponse.From("Other records use this record, so the change was not saved. Refresh the data and try again.")),
        _ when exception.HasSqlError(SqlErrors.ConstraintViolation) =>
            (StatusCodes.Status409Conflict, ErrorResponse.From("The change breaks a data rule, so it was not saved. Check the values and try again.")),
        _ when exception.HasSqlError(SqlErrors.Deadlock) =>
            (StatusCodes.Status409Conflict, ErrorResponse.From("The request conflicted with another request. Try again.")),
        BadHttpRequestException e => (e.StatusCode, ErrorResponse.From("The request is not valid.")),
        _ => (StatusCodes.Status500InternalServerError, ErrorResponse.From("An unexpected error occurred. Try again later."))
    };
}
