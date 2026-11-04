using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using EscapeHub.Infrastructure.Configuration;

namespace EscapeHub.Infrastructure.Services;

public record PolarCheckout(string Id, string Url, string Status, long? TotalAmount, string? Currency, Dictionary<string, string>? Metadata);

public record PolarOrder(string Id, long RefundableAmount, long RefundableTaxAmount);

public record PolarRefund(string Id, string Status);

public class PolarClient
{
    private const decimal BamPerEur = 1.95583m;
    private const long MinimumEurCents = 50;

    private static readonly JsonSerializerOptions Json = new() { PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower };

    private readonly HttpClient _http;
    private readonly PolarOptions _options;

    public PolarClient(HttpClient http, PolarOptions options)
    {
        _options = options;
        _http = http;
        _http.BaseAddress = new Uri(options.ApiUrl.TrimEnd('/') + "/");
        _http.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", options.AccessToken);
    }

    public async Task<PolarCheckout> CreateCheckoutAsync(int bookingId, int clientId, decimal bamTotal)
    {
        var eurCents = Math.Max(MinimumEurCents, (long)Math.Round(bamTotal / BamPerEur * 100, MidpointRounding.AwayFromZero));
        var bamCents = (long)Math.Round(bamTotal * 100, MidpointRounding.AwayFromZero);
        var body = new
        {
            products = new[] { _options.ProductId },
            prices = new Dictionary<string, object[]>
            {
                [_options.ProductId] =
                [
                    new { amount_type = "fixed", price_currency = "eur", price_amount = eurCents },
                    new { amount_type = "fixed", price_currency = "bam", price_amount = bamCents }
                ]
            },
            currency = "bam",
            external_customer_id = $"escapehub-client-{clientId}",
            metadata = new { booking_id = bookingId.ToString() },
            success_url = $"{_options.SuccessUrl}?checkout_id={{CHECKOUT_ID}}"
        };
        var response = await _http.PostAsJsonAsync("v1/checkouts/", body);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<PolarCheckout>(Json))!;
    }

    public async Task<PolarCheckout> GetCheckoutAsync(string checkoutId) =>
        (await _http.GetFromJsonAsync<PolarCheckout>($"v1/checkouts/{checkoutId}", Json))!;

    public async Task<string?> GetOrderIdAsync(string checkoutId)
    {
        var orders = await _http.GetFromJsonAsync<OrderList>($"v1/orders/?checkout_id={checkoutId}", Json);
        return orders?.Items.FirstOrDefault()?.Id;
    }

    public async Task<PolarOrder> GetOrderAsync(string orderId) =>
        (await _http.GetFromJsonAsync<PolarOrder>($"v1/orders/{orderId}", Json))!;

    public async Task<PolarRefund> CreateRefundAsync(string orderId, long cents, long taxCents, string comment)
    {
        var body = new { order_id = orderId, reason = "customer_request", amount = cents, tax_amount = taxCents, comment };
        var response = await _http.PostAsJsonAsync("v1/refunds/", body);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<PolarRefund>(Json))!;
    }

    private record OrderList(List<OrderItem> Items);

    private record OrderItem(string Id);
}
