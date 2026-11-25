using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SchoolGradingApi.Migrations
{
    /// <inheritdoc />
    public partial class AddSoftDelete : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "isDeleted",
                table: "users",
                type: "tinyint(1)",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "isDeleted",
                table: "classes",
                type: "tinyint(1)",
                nullable: false,
                defaultValue: false);

            migrationBuilder.UpdateData(
                table: "classes",
                keyColumn: "Id",
                keyValue: 1,
                column: "isDeleted",
                value: false);

            migrationBuilder.UpdateData(
                table: "classes",
                keyColumn: "Id",
                keyValue: 2,
                column: "isDeleted",
                value: false);

            migrationBuilder.UpdateData(
                table: "classes",
                keyColumn: "Id",
                keyValue: 3,
                column: "isDeleted",
                value: false);

            migrationBuilder.UpdateData(
                table: "classes",
                keyColumn: "Id",
                keyValue: 4,
                column: "isDeleted",
                value: false);

            migrationBuilder.UpdateData(
                table: "classes",
                keyColumn: "Id",
                keyValue: 5,
                column: "isDeleted",
                value: false);

            migrationBuilder.UpdateData(
                table: "users",
                keyColumn: "Id",
                keyValue: 1,
                column: "isDeleted",
                value: false);

            migrationBuilder.UpdateData(
                table: "users",
                keyColumn: "Id",
                keyValue: 2,
                column: "isDeleted",
                value: false);

            migrationBuilder.UpdateData(
                table: "users",
                keyColumn: "Id",
                keyValue: 3,
                column: "isDeleted",
                value: false);

            migrationBuilder.UpdateData(
                table: "users",
                keyColumn: "Id",
                keyValue: 4,
                column: "isDeleted",
                value: false);

            migrationBuilder.UpdateData(
                table: "users",
                keyColumn: "Id",
                keyValue: 5,
                column: "isDeleted",
                value: false);

            migrationBuilder.UpdateData(
                table: "users",
                keyColumn: "Id",
                keyValue: 6,
                column: "isDeleted",
                value: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "isDeleted",
                table: "users");

            migrationBuilder.DropColumn(
                name: "isDeleted",
                table: "classes");
        }
    }
}
