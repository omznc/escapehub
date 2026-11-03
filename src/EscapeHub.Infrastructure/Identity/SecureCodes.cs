using System.Security.Cryptography;

namespace EscapeHub.Infrastructure.Identity;

public static class SecureCodes
{
    private const string VoucherAlphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

    public static string NumericCode(int length) =>
        RandomNumberGenerator.GetInt32(0, (int)Math.Pow(10, length)).ToString($"D{length}");

    public static string Voucher() =>
        $"ESC-{RandomNumberGenerator.GetString(VoucherAlphabet, 4)}-{RandomNumberGenerator.GetString(VoucherAlphabet, 4)}";
}
