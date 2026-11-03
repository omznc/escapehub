using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EscapeHub.Infrastructure.Migrations
{
    public partial class ManagerScopeBookingWorkflow : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AspNetUsers_Cities_CityId",
                table: "AspNetUsers");

            migrationBuilder.DropForeignKey(
                name: "FK_Bookings_Promotions_PromotionId",
                table: "Bookings");

            migrationBuilder.DropForeignKey(
                name: "FK_LoyaltyTransactions_AspNetUsers_ClientId",
                table: "LoyaltyTransactions");

            migrationBuilder.DropForeignKey(
                name: "FK_LoyaltyTransactions_Bookings_BookingId",
                table: "LoyaltyTransactions");

            migrationBuilder.DropForeignKey(
                name: "FK_Promotions_Rooms_RoomId",
                table: "Promotions");

            migrationBuilder.DropForeignKey(
                name: "FK_Reviews_Rooms_RoomId",
                table: "Reviews");

            migrationBuilder.DropForeignKey(
                name: "FK_RewardRedemptions_AspNetUsers_ClientId",
                table: "RewardRedemptions");

            migrationBuilder.DropForeignKey(
                name: "FK_Rooms_Cities_CityId",
                table: "Rooms");

            migrationBuilder.DropForeignKey(
                name: "FK_RoomScenarios_DifficultyLevels_DifficultyOverrideId",
                table: "RoomScenarios");

            migrationBuilder.DropIndex(
                name: "IX_Promotions_RoomId",
                table: "Promotions");

            migrationBuilder.DropIndex(
                name: "IX_Notifications_UserId",
                table: "Notifications");

            migrationBuilder.DropIndex(
                name: "IX_LoyaltyTransactions_BookingId",
                table: "LoyaltyTransactions");

            migrationBuilder.DropIndex(
                name: "IX_Cities_CountryId",
                table: "Cities");

            migrationBuilder.DropIndex(
                name: "IX_Bookings_ScheduleId",
                table: "Bookings");

            migrationBuilder.DropColumn(
                name: "IsAvailable",
                table: "Schedules");

            migrationBuilder.DropColumn(
                name: "RoomId",
                table: "Promotions");

            migrationBuilder.DropColumn(
                name: "Email",
                table: "BookingMembers");

            migrationBuilder.RenameColumn(
                name: "RedeemedAt",
                table: "RewardRedemptions",
                newName: "UpdatedAt");

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Themes",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "Themes",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AlterColumn<DateTime>(
                name: "UpdatedAt",
                table: "Schedules",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "GETUTCDATE()");

            migrationBuilder.AlterColumn<DateTime>(
                name: "Date",
                table: "Schedules",
                type: "date",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "Schedules",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "GETUTCDATE()");

            migrationBuilder.AddColumn<bool>(
                name: "IsBlocked",
                table: "Schedules",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AlterColumn<DateTime>(
                name: "UpdatedAt",
                table: "RoomScenarios",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "GETUTCDATE()");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "RoomScenarios",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "GETUTCDATE()");

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "RoomScenarios",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AlterColumn<DateTime>(
                name: "UpdatedAt",
                table: "Rooms",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "GETUTCDATE()");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "Rooms",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "GETUTCDATE()");

            migrationBuilder.AddColumn<int>(
                name: "ManagerId",
                table: "Rooms",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "RoomResults",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "RewardTypes",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<bool>(
                name: "IsPercentage",
                table: "RewardTypes",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "RewardTypes",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AlterColumn<string>(
                name: "Code",
                table: "RewardRedemptions",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(100)",
                oldMaxLength: 100);

            migrationBuilder.AddColumn<int>(
                name: "BookingId",
                table: "RewardRedemptions",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "RewardRedemptions",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AlterColumn<DateTime>(
                name: "UpdatedAt",
                table: "Reviews",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "GETUTCDATE()");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "Reviews",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "GETUTCDATE()");

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "PromotionTypes",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<bool>(
                name: "IsPercentage",
                table: "PromotionTypes",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "PromotionTypes",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AlterColumn<DateTime>(
                name: "UpdatedAt",
                table: "Promotions",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "GETUTCDATE()");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "Promotions",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "GETUTCDATE()");

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Promotions",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "Notifications",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<int>(
                name: "RewardRedemptionId",
                table: "LoyaltyTransactions",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "LoyaltyTransactions",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AlterColumn<DateTime>(
                name: "UpdatedAt",
                table: "LoyaltyRewards",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "GETUTCDATE()");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "LoyaltyRewards",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "GETUTCDATE()");

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "LoyaltyRewards",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "DifficultyLevels",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "DifficultyLevels",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Countries",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "Countries",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Cities",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "Cities",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "BookingStatuses",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "BookingStatuses",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AlterColumn<DateTime>(
                name: "UpdatedAt",
                table: "Bookings",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "GETUTCDATE()");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "Bookings",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "GETUTCDATE()");

            migrationBuilder.AddColumn<DateTime>(
                name: "ReminderSentAt",
                table: "Bookings",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "Subtotal",
                table: "Bookings",
                type: "decimal(10,2)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "BookingMembers",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "BookingMembers",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AlterColumn<string>(
                name: "Email",
                table: "AspNetUsers",
                type: "nvarchar(256)",
                maxLength: 256,
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(256)",
                oldMaxLength: 256,
                oldNullable: true);

            migrationBuilder.CreateTable(
                name: "BookingStatusHistory",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    BookingId = table.Column<int>(type: "int", nullable: false),
                    FromStatusId = table.Column<int>(type: "int", nullable: true),
                    ToStatusId = table.Column<int>(type: "int", nullable: false),
                    ChangedById = table.Column<int>(type: "int", nullable: true),
                    Reason = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BookingStatusHistory", x => x.Id);
                    table.ForeignKey(
                        name: "FK_BookingStatusHistory_AspNetUsers_ChangedById",
                        column: x => x.ChangedById,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_BookingStatusHistory_BookingStatuses_FromStatusId",
                        column: x => x.FromStatusId,
                        principalTable: "BookingStatuses",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_BookingStatusHistory_BookingStatuses_ToStatusId",
                        column: x => x.ToStatusId,
                        principalTable: "BookingStatuses",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_BookingStatusHistory_Bookings_BookingId",
                        column: x => x.BookingId,
                        principalTable: "Bookings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PasswordResetCodes",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    CodeHash = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UsedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    FailedAttempts = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PasswordResetCodes", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PasswordResetCodes_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PromotionRooms",
                columns: table => new
                {
                    PromotionsId = table.Column<int>(type: "int", nullable: false),
                    RoomsId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PromotionRooms", x => new { x.PromotionsId, x.RoomsId });
                    table.ForeignKey(
                        name: "FK_PromotionRooms_Promotions_PromotionsId",
                        column: x => x.PromotionsId,
                        principalTable: "Promotions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PromotionRooms_Rooms_RoomsId",
                        column: x => x.RoomsId,
                        principalTable: "Rooms",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "SystemSettings",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CompanyName = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    ContactEmail = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    ContactPhone = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: true),
                    PointsPerPlayer = table.Column<int>(type: "int", nullable: false),
                    PointsPerCurrencyUnit = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    CancellationDeadlineHours = table.Column<int>(type: "int", nullable: false),
                    ReminderHoursBefore = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SystemSettings", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Themes_Name",
                table: "Themes",
                column: "Name",
                unique: true);

            migrationBuilder.AddCheckConstraint(
                name: "CK_Schedules_Time",
                table: "Schedules",
                sql: "[EndTime] > [StartTime]");

            migrationBuilder.CreateIndex(
                name: "IX_Rooms_ManagerId",
                table: "Rooms",
                column: "ManagerId");

            migrationBuilder.CreateIndex(
                name: "IX_Rooms_Name",
                table: "Rooms",
                column: "Name",
                unique: true);

            migrationBuilder.AddCheckConstraint(
                name: "CK_Rooms_Players",
                table: "Rooms",
                sql: "[MinPlayers] >= 1 AND [MaxPlayers] >= [MinPlayers]");

            migrationBuilder.CreateIndex(
                name: "IX_RewardTypes_Name",
                table: "RewardTypes",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_RewardRedemptions_BookingId",
                table: "RewardRedemptions",
                column: "BookingId",
                unique: true,
                filter: "[BookingId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_RewardRedemptions_Code",
                table: "RewardRedemptions",
                column: "Code",
                unique: true);

            migrationBuilder.AddCheckConstraint(
                name: "CK_Reviews_Rating",
                table: "Reviews",
                sql: "[Rating] BETWEEN 1 AND 5");

            migrationBuilder.CreateIndex(
                name: "IX_PromotionTypes_Name",
                table: "PromotionTypes",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_UserId_IsRead",
                table: "Notifications",
                columns: new[] { "UserId", "IsRead" });

            migrationBuilder.CreateIndex(
                name: "IX_LoyaltyTransactions_BookingId_TransactionType",
                table: "LoyaltyTransactions",
                columns: new[] { "BookingId", "TransactionType" },
                unique: true,
                filter: "[BookingId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_LoyaltyTransactions_RewardRedemptionId",
                table: "LoyaltyTransactions",
                column: "RewardRedemptionId");

            migrationBuilder.CreateIndex(
                name: "IX_DifficultyLevels_Name",
                table: "DifficultyLevels",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Countries_Name",
                table: "Countries",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Cities_CountryId_Name",
                table: "Cities",
                columns: new[] { "CountryId", "Name" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_BookingStatuses_Name",
                table: "BookingStatuses",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_ScheduleId",
                table: "Bookings",
                column: "ScheduleId",
                unique: true,
                filter: "[BookingStatusId] <> 4 AND [BookingStatusId] <> 6");

            migrationBuilder.CreateIndex(
                name: "IX_BookingStatusHistory_BookingId",
                table: "BookingStatusHistory",
                column: "BookingId");

            migrationBuilder.CreateIndex(
                name: "IX_BookingStatusHistory_ChangedById",
                table: "BookingStatusHistory",
                column: "ChangedById");

            migrationBuilder.CreateIndex(
                name: "IX_BookingStatusHistory_FromStatusId",
                table: "BookingStatusHistory",
                column: "FromStatusId");

            migrationBuilder.CreateIndex(
                name: "IX_BookingStatusHistory_ToStatusId",
                table: "BookingStatusHistory",
                column: "ToStatusId");

            migrationBuilder.CreateIndex(
                name: "IX_PasswordResetCodes_UserId_ExpiresAt",
                table: "PasswordResetCodes",
                columns: new[] { "UserId", "ExpiresAt" });

            migrationBuilder.CreateIndex(
                name: "IX_PromotionRooms_RoomsId",
                table: "PromotionRooms",
                column: "RoomsId");

            migrationBuilder.AddForeignKey(
                name: "FK_AspNetUsers_Cities_CityId",
                table: "AspNetUsers",
                column: "CityId",
                principalTable: "Cities",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Bookings_Promotions_PromotionId",
                table: "Bookings",
                column: "PromotionId",
                principalTable: "Promotions",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_LoyaltyTransactions_AspNetUsers_ClientId",
                table: "LoyaltyTransactions",
                column: "ClientId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_LoyaltyTransactions_Bookings_BookingId",
                table: "LoyaltyTransactions",
                column: "BookingId",
                principalTable: "Bookings",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_LoyaltyTransactions_RewardRedemptions_RewardRedemptionId",
                table: "LoyaltyTransactions",
                column: "RewardRedemptionId",
                principalTable: "RewardRedemptions",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Reviews_Rooms_RoomId",
                table: "Reviews",
                column: "RoomId",
                principalTable: "Rooms",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_RewardRedemptions_AspNetUsers_ClientId",
                table: "RewardRedemptions",
                column: "ClientId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_RewardRedemptions_Bookings_BookingId",
                table: "RewardRedemptions",
                column: "BookingId",
                principalTable: "Bookings",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Rooms_AspNetUsers_ManagerId",
                table: "Rooms",
                column: "ManagerId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Rooms_Cities_CityId",
                table: "Rooms",
                column: "CityId",
                principalTable: "Cities",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_RoomScenarios_DifficultyLevels_DifficultyOverrideId",
                table: "RoomScenarios",
                column: "DifficultyOverrideId",
                principalTable: "DifficultyLevels",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AspNetUsers_Cities_CityId",
                table: "AspNetUsers");

            migrationBuilder.DropForeignKey(
                name: "FK_Bookings_Promotions_PromotionId",
                table: "Bookings");

            migrationBuilder.DropForeignKey(
                name: "FK_LoyaltyTransactions_AspNetUsers_ClientId",
                table: "LoyaltyTransactions");

            migrationBuilder.DropForeignKey(
                name: "FK_LoyaltyTransactions_Bookings_BookingId",
                table: "LoyaltyTransactions");

            migrationBuilder.DropForeignKey(
                name: "FK_LoyaltyTransactions_RewardRedemptions_RewardRedemptionId",
                table: "LoyaltyTransactions");

            migrationBuilder.DropForeignKey(
                name: "FK_Reviews_Rooms_RoomId",
                table: "Reviews");

            migrationBuilder.DropForeignKey(
                name: "FK_RewardRedemptions_AspNetUsers_ClientId",
                table: "RewardRedemptions");

            migrationBuilder.DropForeignKey(
                name: "FK_RewardRedemptions_Bookings_BookingId",
                table: "RewardRedemptions");

            migrationBuilder.DropForeignKey(
                name: "FK_Rooms_AspNetUsers_ManagerId",
                table: "Rooms");

            migrationBuilder.DropForeignKey(
                name: "FK_Rooms_Cities_CityId",
                table: "Rooms");

            migrationBuilder.DropForeignKey(
                name: "FK_RoomScenarios_DifficultyLevels_DifficultyOverrideId",
                table: "RoomScenarios");

            migrationBuilder.DropTable(
                name: "BookingStatusHistory");

            migrationBuilder.DropTable(
                name: "PasswordResetCodes");

            migrationBuilder.DropTable(
                name: "PromotionRooms");

            migrationBuilder.DropTable(
                name: "SystemSettings");

            migrationBuilder.DropIndex(
                name: "IX_Themes_Name",
                table: "Themes");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Schedules_Time",
                table: "Schedules");

            migrationBuilder.DropIndex(
                name: "IX_Rooms_ManagerId",
                table: "Rooms");

            migrationBuilder.DropIndex(
                name: "IX_Rooms_Name",
                table: "Rooms");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Rooms_Players",
                table: "Rooms");

            migrationBuilder.DropIndex(
                name: "IX_RewardTypes_Name",
                table: "RewardTypes");

            migrationBuilder.DropIndex(
                name: "IX_RewardRedemptions_BookingId",
                table: "RewardRedemptions");

            migrationBuilder.DropIndex(
                name: "IX_RewardRedemptions_Code",
                table: "RewardRedemptions");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Reviews_Rating",
                table: "Reviews");

            migrationBuilder.DropIndex(
                name: "IX_PromotionTypes_Name",
                table: "PromotionTypes");

            migrationBuilder.DropIndex(
                name: "IX_Notifications_UserId_IsRead",
                table: "Notifications");

            migrationBuilder.DropIndex(
                name: "IX_LoyaltyTransactions_BookingId_TransactionType",
                table: "LoyaltyTransactions");

            migrationBuilder.DropIndex(
                name: "IX_LoyaltyTransactions_RewardRedemptionId",
                table: "LoyaltyTransactions");

            migrationBuilder.DropIndex(
                name: "IX_DifficultyLevels_Name",
                table: "DifficultyLevels");

            migrationBuilder.DropIndex(
                name: "IX_Countries_Name",
                table: "Countries");

            migrationBuilder.DropIndex(
                name: "IX_Cities_CountryId_Name",
                table: "Cities");

            migrationBuilder.DropIndex(
                name: "IX_BookingStatuses_Name",
                table: "BookingStatuses");

            migrationBuilder.DropIndex(
                name: "IX_Bookings_ScheduleId",
                table: "Bookings");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Themes");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "Themes");

            migrationBuilder.DropColumn(
                name: "IsBlocked",
                table: "Schedules");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "RoomScenarios");

            migrationBuilder.DropColumn(
                name: "ManagerId",
                table: "Rooms");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "RoomResults");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "RewardTypes");

            migrationBuilder.DropColumn(
                name: "IsPercentage",
                table: "RewardTypes");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "RewardTypes");

            migrationBuilder.DropColumn(
                name: "BookingId",
                table: "RewardRedemptions");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "RewardRedemptions");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "PromotionTypes");

            migrationBuilder.DropColumn(
                name: "IsPercentage",
                table: "PromotionTypes");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "PromotionTypes");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "Promotions");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "Notifications");

            migrationBuilder.DropColumn(
                name: "RewardRedemptionId",
                table: "LoyaltyTransactions");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "LoyaltyTransactions");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "LoyaltyRewards");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "DifficultyLevels");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "DifficultyLevels");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Countries");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "Countries");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Cities");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "Cities");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "BookingStatuses");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "BookingStatuses");

            migrationBuilder.DropColumn(
                name: "ReminderSentAt",
                table: "Bookings");

            migrationBuilder.DropColumn(
                name: "Subtotal",
                table: "Bookings");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "BookingMembers");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "BookingMembers");

            migrationBuilder.RenameColumn(
                name: "UpdatedAt",
                table: "RewardRedemptions",
                newName: "RedeemedAt");

            migrationBuilder.AlterColumn<DateTime>(
                name: "UpdatedAt",
                table: "Schedules",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "GETUTCDATE()",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<DateTime>(
                name: "Date",
                table: "Schedules",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "date");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "Schedules",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "GETUTCDATE()",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AddColumn<bool>(
                name: "IsAvailable",
                table: "Schedules",
                type: "bit",
                nullable: false,
                defaultValue: true);

            migrationBuilder.AlterColumn<DateTime>(
                name: "UpdatedAt",
                table: "RoomScenarios",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "GETUTCDATE()",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "RoomScenarios",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "GETUTCDATE()",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<DateTime>(
                name: "UpdatedAt",
                table: "Rooms",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "GETUTCDATE()",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "Rooms",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "GETUTCDATE()",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<string>(
                name: "Code",
                table: "RewardRedemptions",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50);

            migrationBuilder.AlterColumn<DateTime>(
                name: "UpdatedAt",
                table: "Reviews",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "GETUTCDATE()",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "Reviews",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "GETUTCDATE()",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<DateTime>(
                name: "UpdatedAt",
                table: "Promotions",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "GETUTCDATE()",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "Promotions",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "GETUTCDATE()",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AddColumn<int>(
                name: "RoomId",
                table: "Promotions",
                type: "int",
                nullable: true);

            migrationBuilder.AlterColumn<DateTime>(
                name: "UpdatedAt",
                table: "LoyaltyRewards",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "GETUTCDATE()",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "LoyaltyRewards",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "GETUTCDATE()",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<DateTime>(
                name: "UpdatedAt",
                table: "Bookings",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "GETUTCDATE()",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CreatedAt",
                table: "Bookings",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "GETUTCDATE()",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AddColumn<string>(
                name: "Email",
                table: "BookingMembers",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Email",
                table: "AspNetUsers",
                type: "nvarchar(256)",
                maxLength: 256,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(256)",
                oldMaxLength: 256);

            migrationBuilder.CreateIndex(
                name: "IX_Promotions_RoomId",
                table: "Promotions",
                column: "RoomId");

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_UserId",
                table: "Notifications",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_LoyaltyTransactions_BookingId",
                table: "LoyaltyTransactions",
                column: "BookingId");

            migrationBuilder.CreateIndex(
                name: "IX_Cities_CountryId",
                table: "Cities",
                column: "CountryId");

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_ScheduleId",
                table: "Bookings",
                column: "ScheduleId",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_AspNetUsers_Cities_CityId",
                table: "AspNetUsers",
                column: "CityId",
                principalTable: "Cities",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Bookings_Promotions_PromotionId",
                table: "Bookings",
                column: "PromotionId",
                principalTable: "Promotions",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_LoyaltyTransactions_AspNetUsers_ClientId",
                table: "LoyaltyTransactions",
                column: "ClientId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_LoyaltyTransactions_Bookings_BookingId",
                table: "LoyaltyTransactions",
                column: "BookingId",
                principalTable: "Bookings",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Promotions_Rooms_RoomId",
                table: "Promotions",
                column: "RoomId",
                principalTable: "Rooms",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Reviews_Rooms_RoomId",
                table: "Reviews",
                column: "RoomId",
                principalTable: "Rooms",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_RewardRedemptions_AspNetUsers_ClientId",
                table: "RewardRedemptions",
                column: "ClientId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Rooms_Cities_CityId",
                table: "Rooms",
                column: "CityId",
                principalTable: "Cities",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_RoomScenarios_DifficultyLevels_DifficultyOverrideId",
                table: "RoomScenarios",
                column: "DifficultyOverrideId",
                principalTable: "DifficultyLevels",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }
    }
}
