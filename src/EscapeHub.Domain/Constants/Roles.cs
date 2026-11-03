namespace EscapeHub.Domain.Constants;

public static class Roles
{
    public const string Administrator = "Administrator";
    public const string RoomManager = "RoomManager";
    public const string Client = "Client";
    public const string Staff = Administrator + "," + RoomManager;

    public static readonly string[] All = [Administrator, RoomManager, Client];
    public static readonly string[] StaffRoles = [Administrator, RoomManager];
}
