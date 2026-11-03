using Microsoft.AspNetCore.Identity;

namespace EscapeHub.Domain.Entities;

public class ApplicationRole : IdentityRole<int>
{
    public ApplicationRole() { }

    public ApplicationRole(string roleName) : base(roleName) { }
}
