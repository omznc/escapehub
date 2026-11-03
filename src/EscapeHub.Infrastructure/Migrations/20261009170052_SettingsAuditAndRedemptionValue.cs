using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EscapeHub.Infrastructure.Migrations
{
    public partial class SettingsAuditAndRedemptionValue : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "UpdatedById",
                table: "SystemSettings",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsPercentage",
                table: "RewardRedemptions",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<decimal>(
                name: "Value",
                table: "RewardRedemptions",
                type: "decimal(10,2)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.Sql(
                "UPDATE rr SET rr.Value = lr.Value, rr.IsPercentage = rt.IsPercentage " +
                "FROM RewardRedemptions rr " +
                "JOIN LoyaltyRewards lr ON lr.Id = rr.LoyaltyRewardId " +
                "JOIN RewardTypes rt ON rt.Id = lr.RewardTypeId");

            migrationBuilder.CreateIndex(
                name: "IX_SystemSettings_UpdatedById",
                table: "SystemSettings",
                column: "UpdatedById");

            migrationBuilder.AddForeignKey(
                name: "FK_SystemSettings_AspNetUsers_UpdatedById",
                table: "SystemSettings",
                column: "UpdatedById",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_SystemSettings_AspNetUsers_UpdatedById",
                table: "SystemSettings");

            migrationBuilder.DropIndex(
                name: "IX_SystemSettings_UpdatedById",
                table: "SystemSettings");

            migrationBuilder.DropColumn(
                name: "UpdatedById",
                table: "SystemSettings");

            migrationBuilder.DropColumn(
                name: "IsPercentage",
                table: "RewardRedemptions");

            migrationBuilder.DropColumn(
                name: "Value",
                table: "RewardRedemptions");
        }
    }
}
