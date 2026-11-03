using System;
using EscapeHub.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

#nullable disable

namespace EscapeHub.Infrastructure.Migrations
{
    [DbContext(typeof(AppDbContext))]
    partial class AppDbContextModelSnapshot : ModelSnapshot
    {
        protected override void BuildModel(ModelBuilder modelBuilder)
        {
#pragma warning disable 612, 618
            modelBuilder
                .HasAnnotation("ProductVersion", "8.0.0")
                .HasAnnotation("Relational:MaxIdentifierLength", 128);

            SqlServerModelBuilderExtensions.UseIdentityColumns(modelBuilder);

            modelBuilder.Entity("EscapeHub.Domain.Entities.ApplicationRole", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("ConcurrencyStamp")
                        .IsConcurrencyToken()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("Name")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<string>("NormalizedName")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.HasKey("Id");

                    b.HasIndex("NormalizedName")
                        .IsUnique()
                        .HasDatabaseName("RoleNameIndex")
                        .HasFilter("[NormalizedName] IS NOT NULL");

                    b.ToTable("AspNetRoles", (string)null);
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.ApplicationUser", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<int>("AccessFailedCount")
                        .HasColumnType("int");

                    b.Property<int?>("CityId")
                        .HasColumnType("int");

                    b.Property<string>("ConcurrencyStamp")
                        .IsConcurrencyToken()
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<string>("Email")
                        .IsRequired()
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<bool>("EmailConfirmed")
                        .HasColumnType("bit");

                    b.Property<string>("FirstName")
                        .IsRequired()
                        .HasMaxLength(100)
                        .HasColumnType("nvarchar(100)");

                    b.Property<bool>("IsActive")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("bit")
                        .HasDefaultValue(true);

                    b.Property<string>("LastName")
                        .IsRequired()
                        .HasMaxLength(100)
                        .HasColumnType("nvarchar(100)");

                    b.Property<bool>("LockoutEnabled")
                        .HasColumnType("bit");

                    b.Property<DateTimeOffset?>("LockoutEnd")
                        .HasColumnType("datetimeoffset");

                    b.Property<string>("NormalizedEmail")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<string>("NormalizedUserName")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<string>("PasswordHash")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("PhoneNumber")
                        .HasColumnType("nvarchar(max)");

                    b.Property<bool>("PhoneNumberConfirmed")
                        .HasColumnType("bit");

                    b.Property<string>("ProfilePictureUrl")
                        .HasMaxLength(500)
                        .HasColumnType("nvarchar(500)");

                    b.Property<string>("SecurityStamp")
                        .HasColumnType("nvarchar(max)");

                    b.Property<bool>("TwoFactorEnabled")
                        .HasColumnType("bit");

                    b.Property<DateTime>("UpdatedAt")
                        .HasColumnType("datetime2");

                    b.Property<string>("UserName")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.HasKey("Id");

                    b.HasIndex("CityId");

                    b.HasIndex("NormalizedEmail")
                        .HasDatabaseName("EmailIndex");

                    b.HasIndex("NormalizedUserName")
                        .IsUnique()
                        .HasDatabaseName("UserNameIndex")
                        .HasFilter("[NormalizedUserName] IS NOT NULL");

                    b.ToTable("AspNetUsers", (string)null);
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.Booking", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<int>("BookingStatusId")
                        .HasColumnType("int");

                    b.Property<int>("ClientId")
                        .HasColumnType("int");

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<decimal>("DiscountApplied")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("decimal(10,2)")
                        .HasDefaultValue(0m);

                    b.Property<string>("Notes")
                        .HasMaxLength(1000)
                        .HasColumnType("nvarchar(1000)");

                    b.Property<int>("PlayerCount")
                        .HasColumnType("int");

                    b.Property<int?>("PromotionId")
                        .HasColumnType("int");

                    b.Property<DateTime?>("ReminderSentAt")
                        .HasColumnType("datetime2");

                    b.Property<int>("ScheduleId")
                        .HasColumnType("int");

                    b.Property<decimal>("Subtotal")
                        .HasColumnType("decimal(10,2)");

                    b.Property<decimal>("TotalPrice")
                        .HasColumnType("decimal(10,2)");

                    b.Property<DateTime>("UpdatedAt")
                        .HasColumnType("datetime2");

                    b.HasKey("Id");

                    b.HasIndex("BookingStatusId");

                    b.HasIndex("ClientId");

                    b.HasIndex("PromotionId");

                    b.HasIndex("ScheduleId")
                        .IsUnique()
                        .HasFilter("[BookingStatusId] <> 4 AND [BookingStatusId] <> 6");

                    b.ToTable("Bookings");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.BookingMember", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<int>("BookingId")
                        .HasColumnType("int");

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<string>("ParticipantName")
                        .IsRequired()
                        .HasMaxLength(200)
                        .HasColumnType("nvarchar(200)");

                    b.Property<DateTime>("UpdatedAt")
                        .HasColumnType("datetime2");

                    b.HasKey("Id");

                    b.HasIndex("BookingId");

                    b.ToTable("BookingMembers");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.BookingStatus", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<string>("Name")
                        .IsRequired()
                        .HasMaxLength(100)
                        .HasColumnType("nvarchar(100)");

                    b.Property<DateTime>("UpdatedAt")
                        .HasColumnType("datetime2");

                    b.HasKey("Id");

                    b.HasIndex("Name")
                        .IsUnique();

                    b.ToTable("BookingStatuses");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.BookingStatusHistory", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<int>("BookingId")
                        .HasColumnType("int");

                    b.Property<int?>("ChangedById")
                        .HasColumnType("int");

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<int?>("FromStatusId")
                        .HasColumnType("int");

                    b.Property<string>("Reason")
                        .HasMaxLength(500)
                        .HasColumnType("nvarchar(500)");

                    b.Property<int>("ToStatusId")
                        .HasColumnType("int");

                    b.Property<DateTime>("UpdatedAt")
                        .HasColumnType("datetime2");

                    b.HasKey("Id");

                    b.HasIndex("BookingId");

                    b.HasIndex("ChangedById");

                    b.HasIndex("FromStatusId");

                    b.HasIndex("ToStatusId");

                    b.ToTable("BookingStatusHistory", (string)null);
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.City", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<int>("CountryId")
                        .HasColumnType("int");

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<string>("Name")
                        .IsRequired()
                        .HasMaxLength(100)
                        .HasColumnType("nvarchar(100)");

                    b.Property<DateTime>("UpdatedAt")
                        .HasColumnType("datetime2");

                    b.HasKey("Id");

                    b.HasIndex("CountryId", "Name")
                        .IsUnique();

                    b.ToTable("Cities");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.Country", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<string>("Name")
                        .IsRequired()
                        .HasMaxLength(100)
                        .HasColumnType("nvarchar(100)");

                    b.Property<DateTime>("UpdatedAt")
                        .HasColumnType("datetime2");

                    b.HasKey("Id");

                    b.HasIndex("Name")
                        .IsUnique();

                    b.ToTable("Countries");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.DifficultyLevel", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<string>("Name")
                        .IsRequired()
                        .HasMaxLength(100)
                        .HasColumnType("nvarchar(100)");

                    b.Property<DateTime>("UpdatedAt")
                        .HasColumnType("datetime2");

                    b.Property<int>("Value")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.HasIndex("Name")
                        .IsUnique();

                    b.ToTable("DifficultyLevels");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.LoyaltyReward", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<string>("Description")
                        .IsRequired()
                        .HasMaxLength(1000)
                        .HasColumnType("nvarchar(1000)");

                    b.Property<bool>("IsActive")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("bit")
                        .HasDefaultValue(true);

                    b.Property<bool>("IsDeleted")
                        .HasColumnType("bit");

                    b.Property<string>("Name")
                        .IsRequired()
                        .HasMaxLength(200)
                        .HasColumnType("nvarchar(200)");

                    b.Property<int>("PointsCost")
                        .HasColumnType("int");

                    b.Property<int>("RewardTypeId")
                        .HasColumnType("int");

                    b.Property<DateTime>("UpdatedAt")
                        .HasColumnType("datetime2");

                    b.Property<decimal>("Value")
                        .HasColumnType("decimal(10,2)");

                    b.HasKey("Id");

                    b.HasIndex("RewardTypeId");

                    b.ToTable("LoyaltyRewards");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.LoyaltyTransaction", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<int?>("BookingId")
                        .HasColumnType("int");

                    b.Property<int>("ClientId")
                        .HasColumnType("int");

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<string>("Description")
                        .HasMaxLength(500)
                        .HasColumnType("nvarchar(500)");

                    b.Property<int>("Points")
                        .HasColumnType("int");

                    b.Property<int?>("RewardRedemptionId")
                        .HasColumnType("int");

                    b.Property<int>("TransactionType")
                        .HasColumnType("int");

                    b.Property<DateTime>("UpdatedAt")
                        .HasColumnType("datetime2");

                    b.HasKey("Id");

                    b.HasIndex("ClientId");

                    b.HasIndex("RewardRedemptionId");

                    b.HasIndex("BookingId", "TransactionType")
                        .IsUnique()
                        .HasFilter("[BookingId] IS NOT NULL");

                    b.ToTable("LoyaltyTransactions");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.Notification", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<bool>("IsRead")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("bit")
                        .HasDefaultValue(false);

                    b.Property<string>("Message")
                        .IsRequired()
                        .HasMaxLength(2000)
                        .HasColumnType("nvarchar(2000)");

                    b.Property<string>("Title")
                        .IsRequired()
                        .HasMaxLength(200)
                        .HasColumnType("nvarchar(200)");

                    b.Property<int>("Type")
                        .HasColumnType("int");

                    b.Property<DateTime>("UpdatedAt")
                        .HasColumnType("datetime2");

                    b.Property<int>("UserId")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.HasIndex("UserId", "IsRead");

                    b.ToTable("Notifications");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.PasswordResetCode", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("CodeHash")
                        .IsRequired()
                        .HasMaxLength(500)
                        .HasColumnType("nvarchar(500)");

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<DateTime>("ExpiresAt")
                        .HasColumnType("datetime2");

                    b.Property<int>("FailedAttempts")
                        .HasColumnType("int");

                    b.Property<DateTime>("UpdatedAt")
                        .HasColumnType("datetime2");

                    b.Property<DateTime?>("UsedAt")
                        .HasColumnType("datetime2");

                    b.Property<int>("UserId")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.HasIndex("UserId", "ExpiresAt");

                    b.ToTable("PasswordResetCodes");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.Promotion", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<string>("Description")
                        .IsRequired()
                        .HasMaxLength(1000)
                        .HasColumnType("nvarchar(1000)");

                    b.Property<decimal>("DiscountValue")
                        .HasColumnType("decimal(10,2)");

                    b.Property<DateTime>("EndDate")
                        .HasColumnType("datetime2");

                    b.Property<bool>("IsActive")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("bit")
                        .HasDefaultValue(true);

                    b.Property<bool>("IsDeleted")
                        .HasColumnType("bit");

                    b.Property<string>("Name")
                        .IsRequired()
                        .HasMaxLength(200)
                        .HasColumnType("nvarchar(200)");

                    b.Property<int>("PromotionTypeId")
                        .HasColumnType("int");

                    b.Property<DateTime>("StartDate")
                        .HasColumnType("datetime2");

                    b.Property<DateTime>("UpdatedAt")
                        .HasColumnType("datetime2");

                    b.HasKey("Id");

                    b.HasIndex("PromotionTypeId");

                    b.ToTable("Promotions");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.PromotionType", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<bool>("IsPercentage")
                        .HasColumnType("bit");

                    b.Property<string>("Name")
                        .IsRequired()
                        .HasMaxLength(100)
                        .HasColumnType("nvarchar(100)");

                    b.Property<DateTime>("UpdatedAt")
                        .HasColumnType("datetime2");

                    b.HasKey("Id");

                    b.HasIndex("Name")
                        .IsUnique();

                    b.ToTable("PromotionTypes");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.Review", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<int>("ClientId")
                        .HasColumnType("int");

                    b.Property<string>("Comment")
                        .HasMaxLength(2000)
                        .HasColumnType("nvarchar(2000)");

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<bool>("IsDeleted")
                        .HasColumnType("bit");

                    b.Property<bool>("IsHidden")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("bit")
                        .HasDefaultValue(false);

                    b.Property<int>("Rating")
                        .HasColumnType("int");

                    b.Property<int>("RoomId")
                        .HasColumnType("int");

                    b.Property<DateTime>("UpdatedAt")
                        .HasColumnType("datetime2");

                    b.HasKey("Id");

                    b.HasIndex("ClientId");

                    b.HasIndex("RoomId", "ClientId")
                        .IsUnique()
                        .HasFilter("[IsDeleted] = 0");

                    b.ToTable("Reviews", t =>
                        {
                            t.HasCheckConstraint("CK_Reviews_Rating", "[Rating] BETWEEN 1 AND 5");
                        });
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.RewardRedemption", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<int?>("BookingId")
                        .HasColumnType("int");

                    b.Property<int>("ClientId")
                        .HasColumnType("int");

                    b.Property<string>("Code")
                        .IsRequired()
                        .HasMaxLength(50)
                        .HasColumnType("nvarchar(50)");

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<bool>("IsPercentage")
                        .HasColumnType("bit");

                    b.Property<bool>("IsUsed")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("bit")
                        .HasDefaultValue(false);

                    b.Property<int>("LoyaltyRewardId")
                        .HasColumnType("int");

                    b.Property<int>("PointsSpent")
                        .HasColumnType("int");

                    b.Property<DateTime>("UpdatedAt")
                        .HasColumnType("datetime2");

                    b.Property<DateTime?>("UsedAt")
                        .HasColumnType("datetime2");

                    b.Property<decimal>("Value")
                        .HasColumnType("decimal(10,2)");

                    b.HasKey("Id");

                    b.HasIndex("BookingId")
                        .IsUnique()
                        .HasFilter("[BookingId] IS NOT NULL");

                    b.HasIndex("ClientId");

                    b.HasIndex("Code")
                        .IsUnique();

                    b.HasIndex("LoyaltyRewardId");

                    b.ToTable("RewardRedemptions");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.RewardType", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<bool>("IsPercentage")
                        .HasColumnType("bit");

                    b.Property<string>("Name")
                        .IsRequired()
                        .HasMaxLength(100)
                        .HasColumnType("nvarchar(100)");

                    b.Property<DateTime>("UpdatedAt")
                        .HasColumnType("datetime2");

                    b.HasKey("Id");

                    b.HasIndex("Name")
                        .IsUnique();

                    b.ToTable("RewardTypes");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.Room", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("AgeRecommendation")
                        .HasMaxLength(100)
                        .HasColumnType("nvarchar(100)");

                    b.Property<int?>("CityId")
                        .HasColumnType("int");

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<int>("DifficultyLevelId")
                        .HasColumnType("int");

                    b.Property<int>("DurationMinutes")
                        .HasColumnType("int");

                    b.Property<string>("ImageUrl")
                        .HasMaxLength(500)
                        .HasColumnType("nvarchar(500)");

                    b.Property<bool>("IsActive")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("bit")
                        .HasDefaultValue(true);

                    b.Property<bool>("IsDeleted")
                        .HasColumnType("bit");

                    b.Property<string>("LongDescription")
                        .IsRequired()
                        .HasMaxLength(2000)
                        .HasColumnType("nvarchar(2000)");

                    b.Property<int?>("ManagerId")
                        .HasColumnType("int");

                    b.Property<int>("MaxPlayers")
                        .HasColumnType("int");

                    b.Property<int>("MinPlayers")
                        .HasColumnType("int");

                    b.Property<string>("Name")
                        .IsRequired()
                        .HasMaxLength(200)
                        .HasColumnType("nvarchar(200)");

                    b.Property<decimal>("PricePerBooking")
                        .HasColumnType("decimal(10,2)");

                    b.Property<decimal>("PricePerPerson")
                        .HasColumnType("decimal(10,2)");

                    b.Property<string>("ShortDescription")
                        .IsRequired()
                        .HasMaxLength(500)
                        .HasColumnType("nvarchar(500)");

                    b.Property<int>("ThemeId")
                        .HasColumnType("int");

                    b.Property<DateTime>("UpdatedAt")
                        .HasColumnType("datetime2");

                    b.HasKey("Id");

                    b.HasIndex("CityId");

                    b.HasIndex("DifficultyLevelId");

                    b.HasIndex("ManagerId");

                    b.HasIndex("Name")
                        .IsUnique()
                        .HasFilter("[IsDeleted] = 0");

                    b.HasIndex("ThemeId");

                    b.ToTable("Rooms", t =>
                        {
                            t.HasCheckConstraint("CK_Rooms_Players", "[MinPlayers] >= 1 AND [MaxPlayers] >= [MinPlayers]");
                        });
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.RoomResult", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<int>("BookingId")
                        .HasColumnType("int");

                    b.Property<int?>("CompletionTimeMinutes")
                        .HasColumnType("int");

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<bool>("Escaped")
                        .HasColumnType("bit");

                    b.Property<int?>("HintsUsed")
                        .HasColumnType("int");

                    b.Property<string>("ManagerNotes")
                        .HasMaxLength(2000)
                        .HasColumnType("nvarchar(2000)");

                    b.Property<int>("RecordedById")
                        .HasColumnType("int");

                    b.Property<int?>("Score")
                        .HasColumnType("int");

                    b.Property<DateTime>("UpdatedAt")
                        .HasColumnType("datetime2");

                    b.HasKey("Id");

                    b.HasIndex("BookingId")
                        .IsUnique();

                    b.HasIndex("RecordedById");

                    b.ToTable("RoomResults");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.RoomScenario", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<int?>("DifficultyOverrideId")
                        .HasColumnType("int");

                    b.Property<string>("HintPolicy")
                        .HasMaxLength(500)
                        .HasColumnType("nvarchar(500)");

                    b.Property<bool>("IsActive")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("bit")
                        .HasDefaultValue(true);

                    b.Property<bool>("IsDeleted")
                        .HasColumnType("bit");

                    b.Property<string>("Name")
                        .IsRequired()
                        .HasMaxLength(200)
                        .HasColumnType("nvarchar(200)");

                    b.Property<int>("RoomId")
                        .HasColumnType("int");

                    b.Property<string>("Story")
                        .IsRequired()
                        .HasMaxLength(2000)
                        .HasColumnType("nvarchar(2000)");

                    b.Property<DateTime>("UpdatedAt")
                        .HasColumnType("datetime2");

                    b.HasKey("Id");

                    b.HasIndex("DifficultyOverrideId");

                    b.HasIndex("RoomId");

                    b.ToTable("RoomScenarios");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.Schedule", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<DateTime>("Date")
                        .HasColumnType("date");

                    b.Property<TimeSpan>("EndTime")
                        .HasColumnType("time");

                    b.Property<bool>("IsBlocked")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("bit")
                        .HasDefaultValue(false);

                    b.Property<int>("RoomId")
                        .HasColumnType("int");

                    b.Property<TimeSpan>("StartTime")
                        .HasColumnType("time");

                    b.Property<DateTime>("UpdatedAt")
                        .HasColumnType("datetime2");

                    b.HasKey("Id");

                    b.HasIndex("RoomId", "Date", "StartTime")
                        .IsUnique();

                    b.ToTable("Schedules", t =>
                        {
                            t.HasCheckConstraint("CK_Schedules_Time", "[EndTime] > [StartTime]");
                        });
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.SystemSetting", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<int>("CancellationDeadlineHours")
                        .HasColumnType("int");

                    b.Property<string>("CompanyName")
                        .IsRequired()
                        .HasMaxLength(200)
                        .HasColumnType("nvarchar(200)");

                    b.Property<string>("ContactEmail")
                        .IsRequired()
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<string>("ContactPhone")
                        .HasMaxLength(30)
                        .HasColumnType("nvarchar(30)");

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<decimal>("PointsPerCurrencyUnit")
                        .HasColumnType("decimal(10,2)");

                    b.Property<int>("PointsPerPlayer")
                        .HasColumnType("int");

                    b.Property<int>("ReminderHoursBefore")
                        .HasColumnType("int");

                    b.Property<DateTime>("UpdatedAt")
                        .HasColumnType("datetime2");

                    b.Property<int?>("UpdatedById")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.HasIndex("UpdatedById");

                    b.ToTable("SystemSettings");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.Theme", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<string>("Name")
                        .IsRequired()
                        .HasMaxLength(100)
                        .HasColumnType("nvarchar(100)");

                    b.Property<DateTime>("UpdatedAt")
                        .HasColumnType("datetime2");

                    b.HasKey("Id");

                    b.HasIndex("Name")
                        .IsUnique();

                    b.ToTable("Themes");
                });

            modelBuilder.Entity("Microsoft.AspNetCore.Identity.IdentityRoleClaim<int>", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("ClaimType")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("ClaimValue")
                        .HasColumnType("nvarchar(max)");

                    b.Property<int>("RoleId")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.HasIndex("RoleId");

                    b.ToTable("AspNetRoleClaims", (string)null);
                });

            modelBuilder.Entity("Microsoft.AspNetCore.Identity.IdentityUserClaim<int>", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("ClaimType")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("ClaimValue")
                        .HasColumnType("nvarchar(max)");

                    b.Property<int>("UserId")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.HasIndex("UserId");

                    b.ToTable("AspNetUserClaims", (string)null);
                });

            modelBuilder.Entity("Microsoft.AspNetCore.Identity.IdentityUserLogin<int>", b =>
                {
                    b.Property<string>("LoginProvider")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("ProviderKey")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("ProviderDisplayName")
                        .HasColumnType("nvarchar(max)");

                    b.Property<int>("UserId")
                        .HasColumnType("int");

                    b.HasKey("LoginProvider", "ProviderKey");

                    b.HasIndex("UserId");

                    b.ToTable("AspNetUserLogins", (string)null);
                });

            modelBuilder.Entity("Microsoft.AspNetCore.Identity.IdentityUserRole<int>", b =>
                {
                    b.Property<int>("UserId")
                        .HasColumnType("int");

                    b.Property<int>("RoleId")
                        .HasColumnType("int");

                    b.HasKey("UserId", "RoleId");

                    b.HasIndex("RoleId");

                    b.ToTable("AspNetUserRoles", (string)null);
                });

            modelBuilder.Entity("Microsoft.AspNetCore.Identity.IdentityUserToken<int>", b =>
                {
                    b.Property<int>("UserId")
                        .HasColumnType("int");

                    b.Property<string>("LoginProvider")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("Name")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("Value")
                        .HasColumnType("nvarchar(max)");

                    b.HasKey("UserId", "LoginProvider", "Name");

                    b.ToTable("AspNetUserTokens", (string)null);
                });

            modelBuilder.Entity("PromotionRooms", b =>
                {
                    b.Property<int>("PromotionsId")
                        .HasColumnType("int");

                    b.Property<int>("RoomsId")
                        .HasColumnType("int");

                    b.HasKey("PromotionsId", "RoomsId");

                    b.HasIndex("RoomsId");

                    b.ToTable("PromotionRooms");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.ApplicationUser", b =>
                {
                    b.HasOne("EscapeHub.Domain.Entities.City", "City")
                        .WithMany("Users")
                        .HasForeignKey("CityId")
                        .OnDelete(DeleteBehavior.Restrict);

                    b.Navigation("City");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.Booking", b =>
                {
                    b.HasOne("EscapeHub.Domain.Entities.BookingStatus", "BookingStatus")
                        .WithMany("Bookings")
                        .HasForeignKey("BookingStatusId")
                        .OnDelete(DeleteBehavior.Restrict)
                        .IsRequired();

                    b.HasOne("EscapeHub.Domain.Entities.ApplicationUser", "Client")
                        .WithMany("Bookings")
                        .HasForeignKey("ClientId")
                        .OnDelete(DeleteBehavior.Restrict)
                        .IsRequired();

                    b.HasOne("EscapeHub.Domain.Entities.Promotion", "Promotion")
                        .WithMany("Bookings")
                        .HasForeignKey("PromotionId")
                        .OnDelete(DeleteBehavior.Restrict);

                    b.HasOne("EscapeHub.Domain.Entities.Schedule", "Schedule")
                        .WithMany("Bookings")
                        .HasForeignKey("ScheduleId")
                        .OnDelete(DeleteBehavior.Restrict)
                        .IsRequired();

                    b.Navigation("BookingStatus");

                    b.Navigation("Client");

                    b.Navigation("Promotion");

                    b.Navigation("Schedule");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.BookingMember", b =>
                {
                    b.HasOne("EscapeHub.Domain.Entities.Booking", "Booking")
                        .WithMany("BookingMembers")
                        .HasForeignKey("BookingId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("Booking");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.BookingStatusHistory", b =>
                {
                    b.HasOne("EscapeHub.Domain.Entities.Booking", "Booking")
                        .WithMany("StatusHistory")
                        .HasForeignKey("BookingId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.HasOne("EscapeHub.Domain.Entities.ApplicationUser", "ChangedBy")
                        .WithMany()
                        .HasForeignKey("ChangedById")
                        .OnDelete(DeleteBehavior.Restrict);

                    b.HasOne("EscapeHub.Domain.Entities.BookingStatus", "FromStatus")
                        .WithMany()
                        .HasForeignKey("FromStatusId")
                        .OnDelete(DeleteBehavior.Restrict);

                    b.HasOne("EscapeHub.Domain.Entities.BookingStatus", "ToStatus")
                        .WithMany()
                        .HasForeignKey("ToStatusId")
                        .OnDelete(DeleteBehavior.Restrict)
                        .IsRequired();

                    b.Navigation("Booking");

                    b.Navigation("ChangedBy");

                    b.Navigation("FromStatus");

                    b.Navigation("ToStatus");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.City", b =>
                {
                    b.HasOne("EscapeHub.Domain.Entities.Country", "Country")
                        .WithMany("Cities")
                        .HasForeignKey("CountryId")
                        .OnDelete(DeleteBehavior.Restrict)
                        .IsRequired();

                    b.Navigation("Country");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.LoyaltyReward", b =>
                {
                    b.HasOne("EscapeHub.Domain.Entities.RewardType", "RewardType")
                        .WithMany("LoyaltyRewards")
                        .HasForeignKey("RewardTypeId")
                        .OnDelete(DeleteBehavior.Restrict)
                        .IsRequired();

                    b.Navigation("RewardType");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.LoyaltyTransaction", b =>
                {
                    b.HasOne("EscapeHub.Domain.Entities.Booking", "Booking")
                        .WithMany("LoyaltyTransactions")
                        .HasForeignKey("BookingId")
                        .OnDelete(DeleteBehavior.Restrict);

                    b.HasOne("EscapeHub.Domain.Entities.ApplicationUser", "Client")
                        .WithMany("LoyaltyTransactions")
                        .HasForeignKey("ClientId")
                        .OnDelete(DeleteBehavior.Restrict)
                        .IsRequired();

                    b.HasOne("EscapeHub.Domain.Entities.RewardRedemption", "RewardRedemption")
                        .WithMany()
                        .HasForeignKey("RewardRedemptionId")
                        .OnDelete(DeleteBehavior.Restrict);

                    b.Navigation("Booking");

                    b.Navigation("Client");

                    b.Navigation("RewardRedemption");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.Notification", b =>
                {
                    b.HasOne("EscapeHub.Domain.Entities.ApplicationUser", "User")
                        .WithMany("Notifications")
                        .HasForeignKey("UserId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("User");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.PasswordResetCode", b =>
                {
                    b.HasOne("EscapeHub.Domain.Entities.ApplicationUser", "User")
                        .WithMany()
                        .HasForeignKey("UserId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("User");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.Promotion", b =>
                {
                    b.HasOne("EscapeHub.Domain.Entities.PromotionType", "PromotionType")
                        .WithMany("Promotions")
                        .HasForeignKey("PromotionTypeId")
                        .OnDelete(DeleteBehavior.Restrict)
                        .IsRequired();

                    b.Navigation("PromotionType");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.Review", b =>
                {
                    b.HasOne("EscapeHub.Domain.Entities.ApplicationUser", "Client")
                        .WithMany("Reviews")
                        .HasForeignKey("ClientId")
                        .OnDelete(DeleteBehavior.Restrict)
                        .IsRequired();

                    b.HasOne("EscapeHub.Domain.Entities.Room", "Room")
                        .WithMany("Reviews")
                        .HasForeignKey("RoomId")
                        .OnDelete(DeleteBehavior.Restrict)
                        .IsRequired();

                    b.Navigation("Client");

                    b.Navigation("Room");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.RewardRedemption", b =>
                {
                    b.HasOne("EscapeHub.Domain.Entities.Booking", "Booking")
                        .WithOne("RewardRedemption")
                        .HasForeignKey("EscapeHub.Domain.Entities.RewardRedemption", "BookingId")
                        .OnDelete(DeleteBehavior.Restrict);

                    b.HasOne("EscapeHub.Domain.Entities.ApplicationUser", "Client")
                        .WithMany("RewardRedemptions")
                        .HasForeignKey("ClientId")
                        .OnDelete(DeleteBehavior.Restrict)
                        .IsRequired();

                    b.HasOne("EscapeHub.Domain.Entities.LoyaltyReward", "LoyaltyReward")
                        .WithMany("RewardRedemptions")
                        .HasForeignKey("LoyaltyRewardId")
                        .OnDelete(DeleteBehavior.Restrict)
                        .IsRequired();

                    b.Navigation("Booking");

                    b.Navigation("Client");

                    b.Navigation("LoyaltyReward");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.Room", b =>
                {
                    b.HasOne("EscapeHub.Domain.Entities.City", "City")
                        .WithMany("Rooms")
                        .HasForeignKey("CityId")
                        .OnDelete(DeleteBehavior.Restrict);

                    b.HasOne("EscapeHub.Domain.Entities.DifficultyLevel", "DifficultyLevel")
                        .WithMany("Rooms")
                        .HasForeignKey("DifficultyLevelId")
                        .OnDelete(DeleteBehavior.Restrict)
                        .IsRequired();

                    b.HasOne("EscapeHub.Domain.Entities.ApplicationUser", "Manager")
                        .WithMany("ManagedRooms")
                        .HasForeignKey("ManagerId")
                        .OnDelete(DeleteBehavior.Restrict);

                    b.HasOne("EscapeHub.Domain.Entities.Theme", "Theme")
                        .WithMany("Rooms")
                        .HasForeignKey("ThemeId")
                        .OnDelete(DeleteBehavior.Restrict)
                        .IsRequired();

                    b.Navigation("City");

                    b.Navigation("DifficultyLevel");

                    b.Navigation("Manager");

                    b.Navigation("Theme");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.RoomResult", b =>
                {
                    b.HasOne("EscapeHub.Domain.Entities.Booking", "Booking")
                        .WithOne("RoomResult")
                        .HasForeignKey("EscapeHub.Domain.Entities.RoomResult", "BookingId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.HasOne("EscapeHub.Domain.Entities.ApplicationUser", "RecordedBy")
                        .WithMany()
                        .HasForeignKey("RecordedById")
                        .OnDelete(DeleteBehavior.Restrict)
                        .IsRequired();

                    b.Navigation("Booking");

                    b.Navigation("RecordedBy");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.RoomScenario", b =>
                {
                    b.HasOne("EscapeHub.Domain.Entities.DifficultyLevel", "DifficultyOverride")
                        .WithMany()
                        .HasForeignKey("DifficultyOverrideId")
                        .OnDelete(DeleteBehavior.Restrict);

                    b.HasOne("EscapeHub.Domain.Entities.Room", "Room")
                        .WithMany("Scenarios")
                        .HasForeignKey("RoomId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("DifficultyOverride");

                    b.Navigation("Room");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.Schedule", b =>
                {
                    b.HasOne("EscapeHub.Domain.Entities.Room", "Room")
                        .WithMany("Schedules")
                        .HasForeignKey("RoomId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("Room");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.SystemSetting", b =>
                {
                    b.HasOne("EscapeHub.Domain.Entities.ApplicationUser", "UpdatedBy")
                        .WithMany()
                        .HasForeignKey("UpdatedById")
                        .OnDelete(DeleteBehavior.Restrict);

                    b.Navigation("UpdatedBy");
                });

            modelBuilder.Entity("Microsoft.AspNetCore.Identity.IdentityRoleClaim<int>", b =>
                {
                    b.HasOne("EscapeHub.Domain.Entities.ApplicationRole", null)
                        .WithMany()
                        .HasForeignKey("RoleId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("Microsoft.AspNetCore.Identity.IdentityUserClaim<int>", b =>
                {
                    b.HasOne("EscapeHub.Domain.Entities.ApplicationUser", null)
                        .WithMany()
                        .HasForeignKey("UserId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("Microsoft.AspNetCore.Identity.IdentityUserLogin<int>", b =>
                {
                    b.HasOne("EscapeHub.Domain.Entities.ApplicationUser", null)
                        .WithMany()
                        .HasForeignKey("UserId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("Microsoft.AspNetCore.Identity.IdentityUserRole<int>", b =>
                {
                    b.HasOne("EscapeHub.Domain.Entities.ApplicationRole", null)
                        .WithMany()
                        .HasForeignKey("RoleId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.HasOne("EscapeHub.Domain.Entities.ApplicationUser", null)
                        .WithMany()
                        .HasForeignKey("UserId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("Microsoft.AspNetCore.Identity.IdentityUserToken<int>", b =>
                {
                    b.HasOne("EscapeHub.Domain.Entities.ApplicationUser", null)
                        .WithMany()
                        .HasForeignKey("UserId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("PromotionRooms", b =>
                {
                    b.HasOne("EscapeHub.Domain.Entities.Promotion", null)
                        .WithMany()
                        .HasForeignKey("PromotionsId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.HasOne("EscapeHub.Domain.Entities.Room", null)
                        .WithMany()
                        .HasForeignKey("RoomsId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.ApplicationUser", b =>
                {
                    b.Navigation("Bookings");

                    b.Navigation("LoyaltyTransactions");

                    b.Navigation("ManagedRooms");

                    b.Navigation("Notifications");

                    b.Navigation("Reviews");

                    b.Navigation("RewardRedemptions");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.Booking", b =>
                {
                    b.Navigation("BookingMembers");

                    b.Navigation("LoyaltyTransactions");

                    b.Navigation("RewardRedemption");

                    b.Navigation("RoomResult");

                    b.Navigation("StatusHistory");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.BookingStatus", b =>
                {
                    b.Navigation("Bookings");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.City", b =>
                {
                    b.Navigation("Rooms");

                    b.Navigation("Users");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.Country", b =>
                {
                    b.Navigation("Cities");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.DifficultyLevel", b =>
                {
                    b.Navigation("Rooms");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.LoyaltyReward", b =>
                {
                    b.Navigation("RewardRedemptions");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.Promotion", b =>
                {
                    b.Navigation("Bookings");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.PromotionType", b =>
                {
                    b.Navigation("Promotions");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.RewardType", b =>
                {
                    b.Navigation("LoyaltyRewards");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.Room", b =>
                {
                    b.Navigation("Reviews");

                    b.Navigation("Scenarios");

                    b.Navigation("Schedules");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.Schedule", b =>
                {
                    b.Navigation("Bookings");
                });

            modelBuilder.Entity("EscapeHub.Domain.Entities.Theme", b =>
                {
                    b.Navigation("Rooms");
                });
#pragma warning restore 612, 618
        }
    }
}
