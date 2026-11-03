using Microsoft.EntityFrameworkCore;
using EscapeHub.Domain.Entities;

namespace EscapeHub.Infrastructure.Data;

public partial class DataSeeder
{
    private const int PastDays = 30;
    private const int FutureDays = 21;
    private static readonly TimeSpan[] SlotStarts = [new(10, 0, 0), new(14, 0, 0), new(18, 0, 0)];

    private static readonly SeedRoom[] RoomSeeds =
    [
        new("The Deep Stone Crypt", "Access Europa's hidden exo facility",
            "Deep beneath the frozen surface of Europa lies the Deep Stone Crypt, Clovis Bray's most secret facility. Your fireteam must infiltrate the crypt, bypass the security protocols of the Clovis AI and uncover the truth behind the exo program. The station's defenses are escalating. You have 60 minutes before the crypt locks you in forever.",
            "Sci-Fi", "Hard", 3, 6, 60, 28, 140, "12+", "Sarajevo", "roommanager", "deep-stone-crypt.jpg"),
        new("The Whisper", "A Taken blight grows in the European Dead Zone",
            "A strange signal leads you to a hidden cave in the European Dead Zone. Inside, a Taken blight pulses with dark energy. Navigate the twisting green-lit corridors, solve the oracle puzzles and confront the heart of the darkness before time runs out.",
            "Mystery", "Expert", 2, 4, 45, 30, 100, "14+", "Mostar", "ikora", "the-whisper.jpg"),
        new("Shattered Throne", "Navigate the twisting corridors of the Dreaming City",
            "Deep within the Dreaming City lies the Shattered Throne, a dungeon of impossible geometry and ancient Awoken magic. Descend through its halls, defeat the dark manifestations of the curse of Dul Incaru and restore balance to the city. Time bends strangely here. You have 75 minutes.",
            "Fantasy", "Medium", 3, 6, 75, 25, 130, "10+", "Zagreb", "ikora", "shattered-throne.jpg"),
        new("Cauldron Lake", "Something dark stirs beneath the lake",
            "The quiet town of Bright Falls has always had its secrets, but nothing compares to what lurks beneath Cauldron Lake. A dark presence is rising and twists reality around itself. Search the shoreline, dive into the depths and find the manuscript pages that can stop the darkness.",
            "Mystery", "Medium", 2, 5, 60, 24, 110, "14+", "Sarajevo", "roommanager", "cauldron-lake.jpg"),
        new("Bright Falls: Writer's Block", "The Dark Place has manifested in Bright Falls",
            "Alan Wake has been writing, and his stories are bleeding into reality. Shadows move on their own, pages float through the air and a presence watches from every corner. Navigate the twisted streets, solve reality-bending puzzles and confront the darkness with light.",
            "Horror", "Hard", 3, 5, 60, 26, 120, "16+", "Mostar", "eris", "bright-falls.jpg"),
        new("Oh Deer Diner", "A quiet night at the diner takes a strange turn",
            "It is just another quiet night at the Oh Deer Diner in Bright Falls. You came for coffee and pie, but something feels wrong. The radio plays static, the lights flicker and the deer head on the wall seems to watch you. Solve the mystery and get out before closing time.",
            "Adventure", "Easy", 2, 4, 45, 18, 70, "6+", "Sarajevo", "roommanager", "oh-deer-diner.jpg"),
        new("The Lighthouse Keeper", "Keep the light burning through the storm",
            "In 1912 the keeper of the Sv. Ivan lighthouse vanished during the worst storm of the century. His logbook survived, full of coded entries. Climb the tower, decode the log and relight the lamp before the ships hit the rocks.",
            "Historical", "Medium", 2, 5, 60, 22, 90, "12+", "Split", "eris", "lighthouse.jpg")
    ];

    private static readonly (string Room, string Name, string Story, string Hints, bool Easy)[] ScenarioSeeds =
    [
        ("The Deep Stone Crypt", "The Space Walk", "Repair the exo radar dish outside the station before the radiation storm hits.", "3 hints available", false),
        ("The Deep Stone Crypt", "Taniks Reborn", "Taniks has been resurrected by the Crypt. Stop him before he escapes.", "Unlimited hints", true),
        ("The Whisper", "The Oracle Engine", "Align the oracles in the correct sequence to open the path forward.", "2 hints available", false),
        ("The Whisper", "The Blight", "Navigate the heart of the Taken blight and destroy the source.", "3 hints available", false),
        ("Shattered Throne", "The Descent", "Drop into the darkness beneath the Dreaming City. The elevator is not an option.", "2 hints available", false),
        ("Shattered Throne", "Dul Incaru's Chamber", "Confront the dark manifestation of Dul Incaru and break the curse.", "3 hints available", false),
        ("Cauldron Lake", "The Diving Platform", "Search the underwater ruins beneath Cauldron Lake for the first manuscript page.", "3 hints available", false),
        ("Cauldron Lake", "Manuscript Pages", "Collect the scattered manuscript pages to reshape the story and escape the darkness.", "Unlimited hints", true),
        ("Bright Falls: Writer's Block", "The Stage", "The Dark Presence has taken the stage at the town hall. Shine a light on the truth.", "2 hints available", false),
        ("Bright Falls: Writer's Block", "The Typewriter", "Find the typewriter and write the ending that frees Bright Falls.", "3 hints available", false),
        ("Oh Deer Diner", "The Back Room", "What is behind the freezer door? The night shift was never this strange.", "Unlimited hints", false),
        ("Oh Deer Diner", "Last Order", "The diner is closing and the shadows are closing in. Pay your bill and leave.", "2 hints available", false),
        ("The Lighthouse Keeper", "The Logbook", "Decode the last entries of the keeper's logbook.", "3 hints available", false),
        ("The Lighthouse Keeper", "The Lamp Room", "Relight the lamp before midnight with the parts that you find in the tower.", "2 hints available", true)
    ];

    private async Task<List<Room>> SeedRoomsAsync(Dictionary<string, ApplicationUser> users)
    {
        var themes = await _db.Themes.ToDictionaryAsync(t => t.Name, t => t.Id);
        var difficulties = await _db.DifficultyLevels.ToDictionaryAsync(d => d.Name, d => d.Id);
        var cities = await _db.Cities.ToDictionaryAsync(c => c.Name, c => c.Id);

        var rooms = RoomSeeds.Select(seed => new Room
        {
            Name = seed.Name,
            ShortDescription = seed.Short,
            LongDescription = seed.Long,
            ThemeId = themes[seed.Theme],
            DifficultyLevelId = difficulties[seed.Difficulty],
            MinPlayers = seed.MinPlayers,
            MaxPlayers = seed.MaxPlayers,
            DurationMinutes = seed.Duration,
            PricePerPerson = seed.PricePerPerson,
            PricePerBooking = seed.PricePerBooking,
            AgeRecommendation = seed.Age,
            CityId = cities[seed.City],
            ManagerId = users[seed.Manager].Id,
            IsActive = true
        }).ToList();
        _db.Rooms.AddRange(rooms);
        await _db.SaveChangesAsync();

        for (var i = 0; i < rooms.Count; i++)
            rooms[i].ImageUrl = await StoreImageAsync($"rooms/{rooms[i].Id}/{RoomSeeds[i].Image}", RoomSeeds[i].Image);
        await _db.SaveChangesAsync();
        return rooms;
    }

    private async Task SeedScenariosAsync(List<Room> rooms)
    {
        var easy = await _db.DifficultyLevels.FirstAsync(d => d.Name == "Easy");
        _db.RoomScenarios.AddRange(ScenarioSeeds.Select(s => new RoomScenario
        {
            RoomId = rooms.First(r => r.Name == s.Room).Id,
            Name = s.Name,
            Story = s.Story,
            HintPolicy = s.Hints,
            DifficultyOverrideId = s.Easy ? easy.Id : null,
            IsActive = true
        }));
        await _db.SaveChangesAsync();
    }

    private async Task<List<Schedule>> SeedSchedulesAsync(List<Room> rooms, DateTime today)
    {
        var slots = new List<Schedule>();
        for (var r = 0; r < rooms.Count; r++)
        {
            for (var day = -PastDays; day <= FutureDays; day++)
            {
                for (var s = 0; s < SlotStarts.Length; s++)
                {
                    slots.Add(new Schedule
                    {
                        Room = rooms[r],
                        Date = today.AddDays(day),
                        StartTime = SlotStarts[s],
                        EndTime = SlotStarts[s].Add(TimeSpan.FromMinutes(rooms[r].DurationMinutes)),
                        IsBlocked = day > 1 && (day + r + s) % 13 == 0
                    });
                }
            }
        }
        _db.Schedules.AddRange(slots);
        await _db.SaveChangesAsync();
        return slots.OrderBy(s => s.Date).ThenBy(s => s.StartTime).ThenBy(s => s.RoomId).ToList();
    }

    private async Task<Dictionary<string, Promotion>> SeedPromotionsAsync(List<Room> rooms, DateTime today)
    {
        var percentage = await _db.PromotionTypes.FirstAsync(t => t.IsPercentage);
        var fixedAmount = await _db.PromotionTypes.FirstAsync(t => !t.IsPercentage);
        Room RoomNamed(string name) => rooms.First(r => r.Name == name);

        var promotions = new Dictionary<string, Promotion>
        {
            ["spring"] = new()
            {
                Name = "Spring Escape", Description = "15% off every room for the whole season.",
                PromotionType = percentage, DiscountValue = 15, StartDate = today.AddDays(-20), EndDate = today.AddDays(40), IsActive = true
            },
            ["crypt"] = new()
            {
                Name = "Crypt and Lake Weekend", Description = "20 KM off a booking in The Deep Stone Crypt or Cauldron Lake.",
                PromotionType = fixedAmount, DiscountValue = 20, StartDate = today.AddDays(-5), EndDate = today.AddDays(25), IsActive = true,
                Rooms = { RoomNamed("The Deep Stone Crypt"), RoomNamed("Cauldron Lake") }
            },
            ["halloween"] = new()
            {
                Name = "Halloween Fright Night", Description = "25% off the horror room.",
                PromotionType = percentage, DiscountValue = 25, StartDate = today.AddDays(-60), EndDate = today.AddDays(-35), IsActive = true,
                Rooms = { RoomNamed("Bright Falls: Writer's Block") }
            },
            ["teaser"] = new()
            {
                Name = "Summer Teaser", Description = "10 KM off The Whisper. Not yet started.",
                PromotionType = fixedAmount, DiscountValue = 10, StartDate = today.AddDays(30), EndDate = today.AddDays(60), IsActive = false,
                Rooms = { RoomNamed("The Whisper") }
            }
        };
        _db.Promotions.AddRange(promotions.Values);
        await _db.SaveChangesAsync();
        return promotions;
    }

    private async Task<List<LoyaltyReward>> SeedRewardsAsync()
    {
        var percentage = await _db.RewardTypes.FirstAsync(t => t.IsPercentage);
        var fixedAmount = await _db.RewardTypes.FirstAsync(t => !t.IsPercentage);
        var rewards = new List<LoyaltyReward>
        {
            new() { Name = "10% off a booking", Description = "Take 10% off your next booking.", PointsCost = 150, RewardType = percentage, Value = 10 },
            new() { Name = "20 KM voucher", Description = "A 20 KM discount on any room.", PointsCost = 250, RewardType = fixedAmount, Value = 20 },
            new() { Name = "25% off a booking", Description = "A quarter off your next adventure.", PointsCost = 400, RewardType = percentage, Value = 25 },
            new() { Name = "Free session", Description = "Your whole next booking is free.", PointsCost = 1200, RewardType = percentage, Value = 100 },
            new() { Name = "Retired mug voucher", Description = "An old reward that is no longer offered.", PointsCost = 80, RewardType = fixedAmount, Value = 5, IsActive = false }
        };
        _db.LoyaltyRewards.AddRange(rewards);
        await _db.SaveChangesAsync();
        return rewards;
    }

    private record SeedRoom(string Name, string Short, string Long, string Theme, string Difficulty, int MinPlayers, int MaxPlayers,
        int Duration, decimal PricePerPerson, decimal PricePerBooking, string Age, string City, string Manager, string Image);
}
