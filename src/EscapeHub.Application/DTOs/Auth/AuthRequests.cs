using System.ComponentModel.DataAnnotations;
using EscapeHub.Application.DTOs.Common;

namespace EscapeHub.Application.DTOs.Auth;

public class LoginRequest
{
    [Required(ErrorMessage = "Username is required.")]
    [StringLength(256, ErrorMessage = "Username can have at most 256 characters.")]
    public string Username { get; set; } = string.Empty;

    [Required(ErrorMessage = "Password is required.")]
    [StringLength(100, ErrorMessage = "Password can have at most 100 characters.")]
    public string Password { get; set; } = string.Empty;
}

public class RegisterRequest
{
    [Required(ErrorMessage = "Username is required.")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "Username must have between 3 and 50 characters.")]
    [RegularExpression(@"^[a-zA-Z0-9._-]+$", ErrorMessage = "Username can contain only letters, digits, dots, dashes and underscores.")]
    public string Username { get; set; } = string.Empty;

    [Required(ErrorMessage = "Email is required.")]
    [EmailAddress(ErrorMessage = ValidationPatterns.EmailMessage)]
    [StringLength(256, ErrorMessage = "Email can have at most 256 characters.")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Password is required.")]
    [StringLength(100, MinimumLength = 4, ErrorMessage = "Password must have between 4 and 100 characters.")]
    public string Password { get; set; } = string.Empty;

    [Required(ErrorMessage = "First name is required.")]
    [StringLength(100, ErrorMessage = "First name can have at most 100 characters.")]
    public string FirstName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Last name is required.")]
    [StringLength(100, ErrorMessage = "Last name can have at most 100 characters.")]
    public string LastName { get; set; } = string.Empty;

    [RegularExpression(ValidationPatterns.Phone, ErrorMessage = ValidationPatterns.PhoneMessage)]
    public string? Phone { get; set; }

    public int? CityId { get; set; }
}

public class UpdateProfileRequest
{
    [Required(ErrorMessage = "First name is required.")]
    [StringLength(100, ErrorMessage = "First name can have at most 100 characters.")]
    public string FirstName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Last name is required.")]
    [StringLength(100, ErrorMessage = "Last name can have at most 100 characters.")]
    public string LastName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Email is required.")]
    [EmailAddress(ErrorMessage = ValidationPatterns.EmailMessage)]
    [StringLength(256, ErrorMessage = "Email can have at most 256 characters.")]
    public string Email { get; set; } = string.Empty;

    [RegularExpression(ValidationPatterns.Phone, ErrorMessage = ValidationPatterns.PhoneMessage)]
    public string? Phone { get; set; }

    public int? CityId { get; set; }
}

public class ChangePasswordRequest
{
    [Required(ErrorMessage = "Current password is required.")]
    [StringLength(100, ErrorMessage = "Current password can have at most 100 characters.")]
    public string CurrentPassword { get; set; } = string.Empty;

    [Required(ErrorMessage = "New password is required.")]
    [StringLength(100, MinimumLength = 4, ErrorMessage = "New password must have between 4 and 100 characters.")]
    public string NewPassword { get; set; } = string.Empty;
}

public class ForgotPasswordRequest
{
    [Required(ErrorMessage = "Email is required.")]
    [EmailAddress(ErrorMessage = ValidationPatterns.EmailMessage)]
    [StringLength(256, ErrorMessage = "Email can have at most 256 characters.")]
    public string Email { get; set; } = string.Empty;
}

public class ResetPasswordRequest
{
    [Required(ErrorMessage = "Email is required.")]
    [EmailAddress(ErrorMessage = ValidationPatterns.EmailMessage)]
    [StringLength(256, ErrorMessage = "Email can have at most 256 characters.")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Code is required.")]
    [RegularExpression(@"^[0-9]{6}$", ErrorMessage = "Enter the 6-digit code from the email.")]
    public string Code { get; set; } = string.Empty;

    [Required(ErrorMessage = "New password is required.")]
    [StringLength(100, MinimumLength = 4, ErrorMessage = "New password must have between 4 and 100 characters.")]
    public string NewPassword { get; set; } = string.Empty;
}
