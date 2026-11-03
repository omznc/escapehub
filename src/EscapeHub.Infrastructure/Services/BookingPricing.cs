using EscapeHub.Domain.Entities;

namespace EscapeHub.Infrastructure.Services;

public record BookingPrice(decimal Subtotal, decimal PromotionDiscount, decimal VoucherDiscount)
{
    public decimal Discount => PromotionDiscount + VoucherDiscount;
    public decimal Total => Subtotal - Discount;
}

public static class BookingPricing
{
    public static BookingPrice Calculate(Room room, int playerCount, Promotion? promotion, RewardRedemption? voucher)
    {
        var subtotal = Round(room.PricePerBooking + room.PricePerPerson * playerCount);
        var promotionDiscount = promotion == null
            ? 0
            : Discount(subtotal, promotion.DiscountValue, promotion.PromotionType.IsPercentage);
        var voucherDiscount = voucher == null
            ? 0
            : Discount(subtotal - promotionDiscount, voucher.Value, voucher.IsPercentage);
        return new BookingPrice(subtotal, promotionDiscount, voucherDiscount);
    }

    private static decimal Discount(decimal amount, decimal value, bool isPercentage)
    {
        var discount = isPercentage ? amount * Math.Min(value, 100) / 100 : value;
        return Round(Math.Clamp(discount, 0, amount));
    }

    private static decimal Round(decimal value) => Math.Round(value, 2, MidpointRounding.AwayFromZero);
}
