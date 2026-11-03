using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EscapeHub.Infrastructure.Migrations
{
    public partial class SoftDeleteRoomsAndReviews : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Rooms_Name",
                table: "Rooms");

            migrationBuilder.DropIndex(
                name: "IX_Reviews_RoomId_ClientId",
                table: "Reviews");

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Rooms",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Reviews",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateIndex(
                name: "IX_Rooms_Name",
                table: "Rooms",
                column: "Name",
                unique: true,
                filter: "[IsDeleted] = 0");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_RoomId_ClientId",
                table: "Reviews",
                columns: new[] { "RoomId", "ClientId" },
                unique: true,
                filter: "[IsDeleted] = 0");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Rooms_Name",
                table: "Rooms");

            migrationBuilder.DropIndex(
                name: "IX_Reviews_RoomId_ClientId",
                table: "Reviews");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "Rooms");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "Reviews");

            migrationBuilder.CreateIndex(
                name: "IX_Rooms_Name",
                table: "Rooms",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_RoomId_ClientId",
                table: "Reviews",
                columns: new[] { "RoomId", "ClientId" },
                unique: true);
        }
    }
}
