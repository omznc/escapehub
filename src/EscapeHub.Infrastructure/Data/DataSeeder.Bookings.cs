using Microsoft.EntityFrameworkCore;
using EscapeHub.Domain.Entities;
using EscapeHub.Domain.Enums;
using EscapeHub.Infrastructure.Identity;
using EscapeHub.Infrastructure.Services;

namespace EscapeHub.Infrastructure.Data;

public partial class DataSeeder
{
    private const int WelcomeBonus = 200;
    private const int ReviewCount = 18;

    private static readonly string[] GeneratedClients = ["cayde6", "alanwake", "sagaanderson", "drifter", "osiris", "saint14", "tor"];
    private static readonly string[] ParticipantPool = ["Ana", "Haris", "Lejla", "Emir", "Amra", "Tarik", "Selma", "Kenan", "Dino", "Maja"];

    private static readonly string[] ReviewComments =
    [
        "Great puzzles and a very friendly game master.",
        "The atmosphere was amazing. We escaped with two minutes left!",
        "A bit too hard for first-timers, but we loved it.",
        "Perfect for a team building event.",
        "The story kept us hooked from start to finish.",
        "Some props were worn out, but the puzzles were clever.",
        "We will be back for the other scenario.",
        "Scary in the best possible way.",
        "Good value for the price.",
        "The final puzzle was brilliant.",
        "Too many padlocks, not enough story.",
        "Fun for the whole family."
    ];

    private async Task SeedContentAsync()
    {
        var now = _clock.Now;
        var users = await _db.Users.ToDictionaryAsync(u => u.UserName!);
        var rooms = await SeedRoomsAsync(users);
        await SeedScenariosAsync(rooms);

        var data = new SeedData
        {
            Now = now,
            UtcOffset = now - DateTime.UtcNow,
            Users = users,
            Rooms = rooms,
            Promotions = await SeedPromotionsAsync(rooms, now.Date),
            Rewards = await SeedRewardsAsync(),
            Slots = await SeedSchedulesAsync(rooms, now.Date),
            Settings = await _db.SystemSettings.AsNoTracking().OrderBy(s => s.Id).FirstAsync()
        };

        SeedClientStory(data, "mobile", 0);
        SeedClientStory(data, "client", 1);
        SeedOpenSessions(data);
        SeedGeneratedBookings(data);
        await _db.SaveChangesAsync();

        SeedReviews(data);
        SeedNotifications(data);
        await _db.SaveChangesAsync();
    }

    private void SeedClientStory(SeedData data, string userName, int shift)
    {
        var client = data.Users[userName];
        var managed = data.Rooms.Where(r => r.ManagerId == data.Users["roommanager"].Id).ToList();
        Room Pick(int index) => managed[(index + shift) % managed.Count];

        AddPoints(client, WelcomeBonus, TransactionType.Adjusted, "Welcome bonus", data.UtcNow.AddDays(-35));
        AddBooking(data, data.FreeSlot(Pick(0), -28), client, 4, BookingStatusEnum.Completed);
        var used = Redeem(client, data.Rewards[0], data.UtcNow.AddDays(-25));
        AddBooking(data, data.FreeSlot(Pick(1), -20), client, 3, BookingStatusEnum.Completed, voucher: used);
        AddBooking(data, data.FreeSlot(Pick(2), -10), client, 4, BookingStatusEnum.Completed);
        Redeem(client, data.Rewards[1], data.UtcNow.AddDays(-3));
        AddBooking(data, data.FreeSlot(Pick(2), -1), client, 3, BookingStatusEnum.Confirmed);

        AddBooking(data, data.FreeSlot(Pick(0), 3), client, 4, BookingStatusEnum.Confirmed, data.Promotions["spring"]);
        AddBooking(data, data.FreeSlot(Pick(1), 8), client, 3, BookingStatusEnum.Pending);
        AddBooking(data, data.FreeSlot(Pick(2), 6), client, 2, BookingStatusEnum.Cancelled);
    }

    private void SeedOpenSessions(SeedData data)
    {
        var managerId = data.Users["roommanager"].Id;
        var managed = data.Rooms.Where(r => r.ManagerId == managerId).ToList();
        AddBooking(data, data.FreeSlot(managed[0], -1), data.Users["cayde6"], 4, BookingStatusEnum.Confirmed);
        AddBooking(data, data.FreeSlot(managed[1], -1), data.Users["alanwake"], 3, BookingStatusEnum.Confirmed);

        var soon = data.Slots
            .Where(s => s.Room.ManagerId == managerId && !s.IsBlocked && !data.UsedSlots.Contains(s))
            .Where(s => s.StartsAt > data.Now.AddHours(1) && s.StartsAt < data.Now.AddHours(data.Settings.ReminderHoursBefore - 1))
            .Take(2)
            .ToList();
        AddBooking(data, soon[0], data.Users["sagaanderson"], soon[0].Room.MinPlayers, BookingStatusEnum.Confirmed, data.Promotions["spring"]);
        if (soon.Count > 1)
            AddBooking(data, soon[1], data.Users["drifter"], soon[1].Room.MinPlayers, BookingStatusEnum.Confirmed);

        Redeem(data.Users["drifter"], data.Rewards[0], data.UtcNow.AddDays(-2));
    }

    private void SeedGeneratedBookings(SeedData data)
    {
        for (var i = 0; i < data.Slots.Count; i += 5)
        {
            var slot = data.Slots[i];
            if (slot.IsBlocked || data.UsedSlots.Contains(slot)) continue;

            var n = i / 5;
            var room = slot.Room;
            var players = room.MinPlayers + n % (room.MaxPlayers - room.MinPlayers + 1);
            var client = data.Users[GeneratedClients[n % GeneratedClients.Length]];
            AddBooking(data, slot, client, players, GeneratedStatus(slot.StartsAt <= data.Now, n));
        }
    }

    private static BookingStatusEnum GeneratedStatus(bool past, int n) => (past, n % 10) switch
    {
        (true, 3) => BookingStatusEnum.Cancelled,
        (true, 6) => BookingStatusEnum.NoShow,
        (true, 8) => BookingStatusEnum.Rejected,
        (true, _) => BookingStatusEnum.Completed,
        (false, 2) => BookingStatusEnum.Cancelled,
        (false, 4 or 7) => BookingStatusEnum.Pending,
        _ => BookingStatusEnum.Confirmed
    };

    private void AddBooking(SeedData data, Schedule slot, ApplicationUser client, int players, BookingStatusEnum status,
        Promotion? promotion = null, RewardRedemption? voucher = null)
    {
        var room = slot.Room;
        var manager = data.Users.Values.First(u => u.Id == room.ManagerId);
        var price = BookingPricing.Calculate(room, players, promotion, voucher);
        var createdAt = data.ToUtc(Earliest(slot.StartsAt.AddDays(-5), data.Now.AddHours(-6)));

        var booking = new Booking
        {
            Schedule = slot,
            Client = client,
            PlayerCount = players,
            Subtotal = price.Subtotal,
            DiscountApplied = price.Discount,
            TotalPrice = price.Total,
            Promotion = promotion,
            CreatedAt = createdAt,
            ReminderSentAt = slot.StartsAt <= data.Now ? data.ToUtc(slot.StartsAt.AddHours(-data.Settings.ReminderHoursBefore)) : null,
            BookingMembers = ParticipantPool.Skip(slot.Id % 5).Take(Math.Min(players, 3))
                .Select(name => new BookingMember { ParticipantName = name }).ToList()
        };
        ApplyHistory(booking, status, client, manager, createdAt, data.ToUtc(slot.StartsAt.AddHours(2)));

        if (voucher != null)
        {
            voucher.IsUsed = true;
            voucher.UsedAt = createdAt;
            voucher.Booking = booking;
        }
        if (status == BookingStatusEnum.Completed)
            AddResult(data, booking, manager);

        _db.Bookings.Add(booking);
        data.UsedSlots.Add(slot);
        data.Bookings.Add(booking);
    }

    private static void ApplyHistory(Booking booking, BookingStatusEnum status, ApplicationUser client, ApplicationUser manager,
        DateTime createdAt, DateTime finishedAt)
    {
        BookingStateMachine.Start(booking, client.Id);
        foreach (var step in StatusPath(status))
        {
            var changedBy = step == BookingStatusEnum.Cancelled ? client : manager;
            BookingStateMachine.Move(booking, step, changedBy.Id, StatusReason(step));
        }

        var steps = booking.StatusHistory.ToList();
        for (var i = 0; i < steps.Count; i++)
        {
            var finished = steps[i].ToStatusId is (int)BookingStatusEnum.Completed or (int)BookingStatusEnum.NoShow;
            steps[i].CreatedAt = finished ? finishedAt : createdAt.AddHours(3 * i);
        }
    }

    private static BookingStatusEnum[] StatusPath(BookingStatusEnum status) => status switch
    {
        BookingStatusEnum.Confirmed => [BookingStatusEnum.Confirmed],
        BookingStatusEnum.Completed => [BookingStatusEnum.Confirmed, BookingStatusEnum.Completed],
        BookingStatusEnum.NoShow => [BookingStatusEnum.Confirmed, BookingStatusEnum.NoShow],
        BookingStatusEnum.Cancelled => [BookingStatusEnum.Confirmed, BookingStatusEnum.Cancelled],
        BookingStatusEnum.Rejected => [BookingStatusEnum.Rejected],
        _ => []
    };

    private static string? StatusReason(BookingStatusEnum status) => status switch
    {
        BookingStatusEnum.Cancelled => "Our plans changed.",
        BookingStatusEnum.Rejected => "The room is closed for maintenance at this time.",
        _ => null
    };

    private static void AddResult(SeedData data, Booking booking, ApplicationUser manager)
    {
        var slot = booking.Schedule;
        var escaped = slot.Id % 3 != 0;
        var finishedAt = data.ToUtc(slot.StartsAt.AddHours(2));
        booking.RoomResult = new RoomResult
        {
            Escaped = escaped,
            CompletionTimeMinutes = escaped ? slot.Room.DurationMinutes - slot.Id % 15 : slot.Room.DurationMinutes,
            HintsUsed = slot.Id % 4,
            Score = escaped ? 60 + slot.Id % 40 : 20 + slot.Id % 30,
            ManagerNotes = escaped ? "Strong teamwork." : "The team ran out of time on the last puzzle.",
            RecordedById = manager.Id,
            CreatedAt = finishedAt
        };
        booking.LoyaltyTransactions.Add(new LoyaltyTransaction
        {
            ClientId = booking.Client.Id,
            Points = data.Settings.PointsPerPlayer * booking.PlayerCount + (int)Math.Floor(booking.TotalPrice * data.Settings.PointsPerCurrencyUnit),
            TransactionType = TransactionType.Earned,
            Description = $"Session in {slot.Room.Name}",
            CreatedAt = finishedAt
        });
    }

    private RewardRedemption Redeem(ApplicationUser client, LoyaltyReward reward, DateTime at)
    {
        var redemption = new RewardRedemption
        {
            ClientId = client.Id,
            LoyaltyReward = reward,
            PointsSpent = reward.PointsCost,
            Value = reward.Value,
            IsPercentage = reward.RewardType.IsPercentage,
            Code = SecureCodes.Voucher(),
            CreatedAt = at
        };
        _db.LoyaltyTransactions.Add(new LoyaltyTransaction
        {
            ClientId = client.Id,
            Points = -reward.PointsCost,
            TransactionType = TransactionType.Redeemed,
            RewardRedemption = redemption,
            Description = $"Redeemed {reward.Name}",
            CreatedAt = at
        });
        return redemption;
    }

    private void AddPoints(ApplicationUser client, int points, TransactionType type, string description, DateTime at)
    {
        _db.LoyaltyTransactions.Add(new LoyaltyTransaction
        {
            ClientId = client.Id,
            Points = points,
            TransactionType = type,
            Description = description,
            CreatedAt = at
        });
    }

    private void SeedReviews(SeedData data)
    {
        var mobileId = data.Users["mobile"].Id;
        var completed = data.Bookings.Where(b => b.BookingStatusId == (int)BookingStatusEnum.Completed).ToList();
        var unreviewed = completed.First(b => b.ClientId == mobileId);
        var reviewed = completed
            .Where(b => b.ClientId != mobileId || b.Schedule.RoomId != unreviewed.Schedule.RoomId)
            .DistinctBy(b => (b.ClientId, b.Schedule.RoomId))
            .Take(ReviewCount)
            .ToList();

        for (var i = 0; i < reviewed.Count; i++)
        {
            var booking = reviewed[i];
            _db.Reviews.Add(new Review
            {
                RoomId = booking.Schedule.RoomId,
                ClientId = booking.ClientId,
                Rating = i % 7 == 6 ? 2 : 3 + i % 3,
                Comment = ReviewComments[i % ReviewComments.Length],
                IsHidden = i % 6 == 5,
                CreatedAt = data.ToUtc(Earliest(booking.Schedule.StartsAt.AddDays(1), data.Now.AddHours(-1)))
            });
        }
    }

    private void SeedNotifications(SeedData data)
    {
        foreach (var userName in new[] { "mobile", "client", "cayde6" })
        {
            var user = data.Users[userName];
            AddNotification(user, NotificationType.LoyaltyPointsAwarded, "Loyalty points added",
                "You earned loyalty points for your last session.", data.UtcNow.AddDays(-10), true);
            AddNotification(user, NotificationType.RewardRedeemed, "Reward redeemed",
                "Your voucher is ready. Enter the code when you book a session.", data.UtcNow.AddDays(-3), true);
            AddNotification(user, NotificationType.BookingConfirmed, "Booking confirmed",
                "Your next booking is confirmed. See you soon!", data.UtcNow.AddDays(-1), false);
            AddNotification(user, NotificationType.BookingCreated, "Booking received",
                "We received your booking. We will confirm it soon.", data.UtcNow.AddHours(-5), false);
        }

        var pending = data.Bookings.Where(b => b.BookingStatusId == (int)BookingStatusEnum.Pending).ToList();
        var cancelled = data.Bookings.First(b => b.BookingStatusId == (int)BookingStatusEnum.Cancelled && b.Schedule.StartsAt > data.Now);
        foreach (var userName in new[] { "roommanager", "desktop", "administrator" })
        {
            var user = data.Users[userName];
            AddNotification(user, NotificationType.BookingCreated, "New booking", NewBookingText(pending[0]), data.UtcNow.AddDays(-4), true);
            AddNotification(user, NotificationType.BookingCancelled, "Booking cancelled by the client",
                $"{FullName(cancelled.Client)} cancelled the booking for {BookingMapper.Describe(cancelled)}. Reason: {StatusReason(BookingStatusEnum.Cancelled)}",
                data.UtcNow.AddDays(-1), false);
            AddNotification(user, NotificationType.BookingCreated, "New booking", NewBookingText(pending[1]), data.UtcNow.AddHours(-3), false);
        }
    }

    private static string NewBookingText(Booking booking) =>
        $"{FullName(booking.Client)} booked {BookingMapper.Describe(booking)} for {booking.PlayerCount} players. Confirm or reject the booking.";

    private static string FullName(ApplicationUser user) => $"{user.FirstName} {user.LastName}";

    private void AddNotification(ApplicationUser user, NotificationType type, string title, string message, DateTime at, bool isRead) =>
        _db.Notifications.Add(new Notification
        {
            UserId = user.Id,
            Type = type,
            Title = title,
            Message = message,
            IsRead = isRead,
            CreatedAt = at
        });

    private static DateTime Earliest(DateTime first, DateTime second) => first < second ? first : second;

    private sealed class SeedData
    {
        public DateTime Now { get; init; }
        public TimeSpan UtcOffset { get; init; }
        public DateTime UtcNow => ToUtc(Now);
        public Dictionary<string, ApplicationUser> Users { get; init; } = new();
        public List<Room> Rooms { get; init; } = new();
        public Dictionary<string, Promotion> Promotions { get; init; } = new();
        public List<LoyaltyReward> Rewards { get; init; } = new();
        public List<Schedule> Slots { get; init; } = new();
        public SystemSetting Settings { get; init; } = null!;
        public HashSet<Schedule> UsedSlots { get; } = new();
        public List<Booking> Bookings { get; } = new();

        public DateTime ToUtc(DateTime local) => local - UtcOffset;

        public Schedule FreeSlot(Room room, int dayOffset)
        {
            var date = Now.Date.AddDays(dayOffset);
            return Slots.First(s => s.Room == room && s.Date >= date && !s.IsBlocked && !UsedSlots.Contains(s) &&
                                    (dayOffset < 0 || s.StartsAt > Now));
        }
    }
}
