namespace EscapeHub.Application.DTOs.Payments;

public record PaymentStartDto(int PaymentId, string CheckoutUrl, string ReturnUrl);
