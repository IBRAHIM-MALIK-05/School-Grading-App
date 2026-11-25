using System;
using Microsoft.EntityFrameworkCore.Migrations;
using MySql.EntityFrameworkCore.Metadata;

#nullable disable

namespace SchoolGradingApi.Migrations
{
    /// <inheritdoc />
    public partial class AddStudentRemovals : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "student_removals",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    ClassId = table.Column<int>(type: "int", nullable: false),
                    StudentName = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: false),
                    RollNo = table.Column<string>(type: "varchar(10)", maxLength: 10, nullable: false),
                    RemovedById = table.Column<int>(type: "int", nullable: false),
                    RemovedByRole = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false),
                    RemovedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_student_removals", x => x.Id);
                    table.ForeignKey(
                        name: "FK_student_removals_classes_ClassId",
                        column: x => x.ClassId,
                        principalTable: "classes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_student_removals_users_RemovedById",
                        column: x => x.RemovedById,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateIndex(
                name: "IX_student_removals_ClassId",
                table: "student_removals",
                column: "ClassId");

            migrationBuilder.CreateIndex(
                name: "IX_student_removals_RemovedById",
                table: "student_removals",
                column: "RemovedById");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "student_removals");
        }
    }
}
