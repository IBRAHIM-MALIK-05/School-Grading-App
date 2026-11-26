using System;
using Microsoft.EntityFrameworkCore.Migrations;
using MySql.EntityFrameworkCore.Metadata;

#nullable disable

namespace SchoolGradingApi.Migrations
{
    /// <inheritdoc />
    public partial class AddNotifications : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "notifications",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    RecipientUserId = table.Column<int>(type: "int", nullable: false),
                    SenderUserId = table.Column<int>(type: "int", nullable: true),
                    Type = table.Column<string>(type: "varchar(40)", maxLength: 40, nullable: false),
                    Title = table.Column<string>(type: "varchar(150)", maxLength: 150, nullable: false),
                    Message = table.Column<string>(type: "varchar(1000)", maxLength: 1000, nullable: false),
                    IsUrgent = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    IsRead = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    NotificationDate = table.Column<DateTime>(type: "date", nullable: false),
                    AssignmentId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_notifications", x => x.Id);
                    table.ForeignKey(
                        name: "FK_notifications_teaching_assignments_AssignmentId",
                        column: x => x.AssignmentId,
                        principalTable: "teaching_assignments",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_notifications_users_RecipientUserId",
                        column: x => x.RecipientUserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_notifications_users_SenderUserId",
                        column: x => x.SenderUserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "school_settings",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false),
                    ResultDate = table.Column<DateTime>(type: "date", nullable: true),
                    UpdatedByUserId = table.Column<int>(type: "int", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_school_settings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_school_settings_users_UpdatedByUserId",
                        column: x => x.UpdatedByUserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.InsertData(
                table: "school_settings",
                columns: new[] { "Id", "ResultDate", "UpdatedAt", "UpdatedByUserId" },
                values: new object[] { 1, null, null, null });

            migrationBuilder.CreateIndex(
                name: "IX_notifications_AssignmentId",
                table: "notifications",
                column: "AssignmentId");

            migrationBuilder.CreateIndex(
                name: "IX_notifications_RecipientUserId_NotificationDate_Type",
                table: "notifications",
                columns: new[] { "RecipientUserId", "NotificationDate", "Type" });

            migrationBuilder.CreateIndex(
                name: "IX_notifications_SenderUserId",
                table: "notifications",
                column: "SenderUserId");

            migrationBuilder.CreateIndex(
                name: "IX_school_settings_UpdatedByUserId",
                table: "school_settings",
                column: "UpdatedByUserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "notifications");

            migrationBuilder.DropTable(
                name: "school_settings");
        }
    }
}
