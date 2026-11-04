using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EscapeHub.Infrastructure.Migrations
{
    public partial class PaymentRefunds : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "RefundId",
                table: "Payments",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "RefundedAt",
                table: "Payments",
                type: "datetime2",
                nullable: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "RefundId",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "RefundedAt",
                table: "Payments");
        }
    }
}
