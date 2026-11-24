using System;
using Microsoft.EntityFrameworkCore.Migrations;
using MySql.EntityFrameworkCore.Metadata;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace SchoolGradingApi.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterDatabase()
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "subjects",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    Name = table.Column<string>(type: "varchar(50)", maxLength: 50, nullable: false),
                    MaxMarks = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_subjects", x => x.Id);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "users",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    FullName = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: false),
                    LoginId = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: false),
                    ContactEmail = table.Column<string>(type: "varchar(150)", maxLength: 150, nullable: true),
                    PasswordHash = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: false),
                    Role = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false),
                    MustChangePassword = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_users", x => x.Id);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "classes",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    GradeName = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false),
                    Section = table.Column<string>(type: "varchar(5)", maxLength: 5, nullable: false),
                    ClassTeacherId = table.Column<int>(type: "int", nullable: true),
                    ResultsPublishedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_classes", x => x.Id);
                    table.ForeignKey(
                        name: "FK_classes_users_ClassTeacherId",
                        column: x => x.ClassTeacherId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "students",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    FullName = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: false),
                    RollNo = table.Column<string>(type: "varchar(10)", maxLength: 10, nullable: false),
                    ClassId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_students", x => x.Id);
                    table.ForeignKey(
                        name: "FK_students_classes_ClassId",
                        column: x => x.ClassId,
                        principalTable: "classes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "teaching_assignments",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    ClassId = table.Column<int>(type: "int", nullable: false),
                    SubjectId = table.Column<int>(type: "int", nullable: false),
                    TeacherId = table.Column<int>(type: "int", nullable: false),
                    SubmittedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_teaching_assignments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_teaching_assignments_classes_ClassId",
                        column: x => x.ClassId,
                        principalTable: "classes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_teaching_assignments_subjects_SubjectId",
                        column: x => x.SubjectId,
                        principalTable: "subjects",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_teaching_assignments_users_TeacherId",
                        column: x => x.TeacherId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "marks",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    StudentId = table.Column<int>(type: "int", nullable: false),
                    SubjectId = table.Column<int>(type: "int", nullable: false),
                    Obtained = table.Column<int>(type: "int", nullable: false),
                    EnteredById = table.Column<int>(type: "int", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_marks", x => x.Id);
                    table.ForeignKey(
                        name: "FK_marks_students_StudentId",
                        column: x => x.StudentId,
                        principalTable: "students",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_marks_subjects_SubjectId",
                        column: x => x.SubjectId,
                        principalTable: "subjects",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_marks_users_EnteredById",
                        column: x => x.EnteredById,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.InsertData(
                table: "classes",
                columns: new[] { "Id", "ClassTeacherId", "GradeName", "ResultsPublishedAt", "Section" },
                values: new object[] { 5, null, "Class 9", null, "C" });

            migrationBuilder.InsertData(
                table: "subjects",
                columns: new[] { "Id", "MaxMarks", "Name" },
                values: new object[,]
                {
                    { 1, 100, "English" },
                    { 2, 100, "Mathematics" },
                    { 3, 60, "Physics" },
                    { 4, 60, "Chemistry" },
                    { 5, 60, "Biology" }
                });

            migrationBuilder.InsertData(
                table: "users",
                columns: new[] { "Id", "ContactEmail", "CreatedAt", "FullName", "LoginId", "MustChangePassword", "PasswordHash", "Role" },
                values: new object[,]
                {
                    { 1, null, new DateTime(2026, 11, 20, 9, 0, 0, 0, DateTimeKind.Unspecified), "School Admin", "admin@school.com", false, "$2a$11$c6gJO2BSfKjGK2cigDfJZOnxFT6ddgxsJnwSCAYt2VHHGDpaTrTk2", "admin" },
                    { 2, null, new DateTime(2026, 11, 20, 9, 0, 0, 0, DateTimeKind.Unspecified), "VP Sarah", "vp@school.com", false, "$2a$11$knbs2jFie66WoIHXYKVkOetGaC0bkXmUDHQmjGEIDfPLqP2D9rREq", "vp" },
                    { 3, null, new DateTime(2026, 11, 20, 9, 0, 0, 0, DateTimeKind.Unspecified), "Teacher Sania", "sania@school.com", false, "$2a$11$zUYQ3hSJRte1VA7nbAlzwO0h9woXmWqkT0LuUm2mVhfYVeCCWoWfi", "teacher" },
                    { 4, null, new DateTime(2026, 11, 20, 9, 0, 0, 0, DateTimeKind.Unspecified), "Teacher Ahsan", "ahsan@school.com", false, "$2a$11$PvGvQ3bx/UDjVC9CcTBFF.POtBi5GnNJ0HOyAt4fhTsvU1IDEzEoa", "teacher" },
                    { 5, null, new DateTime(2026, 11, 20, 9, 0, 0, 0, DateTimeKind.Unspecified), "Teacher Maryam", "maryam@school.com", false, "$2a$11$iHSQXgmL3I4mPMVdCiK...me1Q.I8AZCK/4fcH.MwqdJ0hXSqa5CK", "teacher" },
                    { 6, null, new DateTime(2026, 11, 20, 9, 0, 0, 0, DateTimeKind.Unspecified), "Teacher Usman", "usman@school.com", false, "$2a$11$kl2OEPRuYn2EsnpUzv8bbeuzGlNUJyCiLAf6l49ujBC6ygeilXizW", "teacher" }
                });

            migrationBuilder.InsertData(
                table: "classes",
                columns: new[] { "Id", "ClassTeacherId", "GradeName", "ResultsPublishedAt", "Section" },
                values: new object[,]
                {
                    { 1, 4, "Class 8", null, "A" },
                    { 2, 3, "Class 8", null, "B" },
                    { 3, 5, "Class 9", null, "A" },
                    { 4, 6, "Class 9", null, "B" }
                });

            migrationBuilder.InsertData(
                table: "students",
                columns: new[] { "Id", "ClassId", "FullName", "RollNo" },
                values: new object[,]
                {
                    { 21, 5, "Areeba", "01" },
                    { 22, 5, "Junaid", "02" },
                    { 23, 5, "Kinza", "03" },
                    { 24, 5, "Rehan", "04" },
                    { 25, 5, "Noor", "05" }
                });

            migrationBuilder.InsertData(
                table: "teaching_assignments",
                columns: new[] { "Id", "ClassId", "SubjectId", "SubmittedAt", "TeacherId" },
                values: new object[,]
                {
                    { 21, 5, 1, null, 4 },
                    { 22, 5, 2, null, 5 },
                    { 23, 5, 3, null, 6 },
                    { 24, 5, 4, null, 3 },
                    { 25, 5, 5, null, 3 }
                });

            migrationBuilder.InsertData(
                table: "students",
                columns: new[] { "Id", "ClassId", "FullName", "RollNo" },
                values: new object[,]
                {
                    { 1, 1, "Ali", "01" },
                    { 2, 1, "Ayesha", "02" },
                    { 3, 1, "Hamza", "03" },
                    { 4, 1, "Hira", "04" },
                    { 5, 1, "Omar", "05" },
                    { 6, 2, "Sarah", "01" },
                    { 7, 2, "Ahmed", "02" },
                    { 8, 2, "Zain", "03" },
                    { 9, 2, "Fatima", "04" },
                    { 10, 2, "Bilal", "05" },
                    { 11, 3, "Saad", "01" },
                    { 12, 3, "Zara", "02" },
                    { 13, 3, "Usama", "03" },
                    { 14, 3, "Mahnoor", "04" },
                    { 15, 3, "Fahad", "05" },
                    { 16, 4, "Danish", "01" },
                    { 17, 4, "Iqra", "02" },
                    { 18, 4, "Hassan", "03" },
                    { 19, 4, "Sana", "04" },
                    { 20, 4, "Talha", "05" }
                });

            migrationBuilder.InsertData(
                table: "teaching_assignments",
                columns: new[] { "Id", "ClassId", "SubjectId", "SubmittedAt", "TeacherId" },
                values: new object[,]
                {
                    { 1, 1, 1, null, 4 },
                    { 2, 1, 2, null, 5 },
                    { 3, 1, 3, null, 6 },
                    { 4, 1, 4, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified), 3 },
                    { 5, 1, 5, null, 3 },
                    { 6, 2, 1, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified), 4 },
                    { 7, 2, 2, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified), 5 },
                    { 8, 2, 3, null, 6 },
                    { 9, 2, 4, null, 3 },
                    { 10, 2, 5, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified), 3 },
                    { 11, 3, 1, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified), 4 },
                    { 12, 3, 2, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified), 5 },
                    { 13, 3, 3, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified), 6 },
                    { 14, 3, 4, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified), 3 },
                    { 15, 3, 5, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified), 3 },
                    { 16, 4, 1, null, 4 },
                    { 17, 4, 2, null, 5 },
                    { 18, 4, 3, null, 6 },
                    { 19, 4, 4, null, 3 },
                    { 20, 4, 5, null, 3 }
                });

            migrationBuilder.InsertData(
                table: "marks",
                columns: new[] { "Id", "EnteredById", "Obtained", "StudentId", "SubjectId", "UpdatedAt" },
                values: new object[,]
                {
                    { 1, 3, 50, 1, 4, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 2, 3, 44, 2, 4, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 3, 3, 57, 3, 4, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 4, 3, 39, 4, 4, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 5, 3, 48, 5, 4, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 6, 4, 85, 6, 1, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 7, 4, 78, 7, 1, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 8, 4, 66, 8, 1, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 9, 4, 91, 9, 1, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 10, 4, 72, 10, 1, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 11, 5, 92, 6, 2, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 12, 5, 81, 7, 2, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 13, 5, 59, 8, 2, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 14, 5, 88, 9, 2, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 15, 5, 70, 10, 2, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 16, 3, 52, 6, 5, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 17, 3, 47, 7, 5, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 18, 3, 40, 8, 5, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 19, 3, 58, 9, 5, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 20, 3, 45, 10, 5, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 21, 6, 55, 6, 3, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 22, 3, 48, 6, 4, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 23, 4, 74, 11, 1, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 24, 4, 88, 12, 1, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 25, 4, 63, 13, 1, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 26, 4, 95, 14, 1, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 27, 4, 58, 15, 1, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 28, 5, 67, 11, 2, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 29, 5, 90, 12, 2, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 30, 5, 72, 13, 2, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 31, 5, 84, 14, 2, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 32, 5, 49, 15, 2, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 33, 6, 41, 11, 3, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 34, 6, 53, 12, 3, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 35, 6, 38, 13, 3, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 36, 6, 57, 14, 3, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 37, 6, 46, 15, 3, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 38, 3, 44, 11, 4, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 39, 3, 56, 12, 4, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 40, 3, 35, 13, 4, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 41, 3, 51, 14, 4, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 42, 3, 42, 15, 4, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 43, 3, 49, 11, 5, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 44, 3, 58, 12, 5, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 45, 3, 43, 13, 5, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 46, 3, 54, 14, 5, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) },
                    { 47, 3, 37, 15, 5, new DateTime(2026, 11, 20, 10, 30, 0, 0, DateTimeKind.Unspecified) }
                });

            migrationBuilder.CreateIndex(
                name: "IX_classes_ClassTeacherId",
                table: "classes",
                column: "ClassTeacherId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_classes_GradeName_Section",
                table: "classes",
                columns: new[] { "GradeName", "Section" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_marks_EnteredById",
                table: "marks",
                column: "EnteredById");

            migrationBuilder.CreateIndex(
                name: "IX_marks_StudentId_SubjectId",
                table: "marks",
                columns: new[] { "StudentId", "SubjectId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_marks_SubjectId",
                table: "marks",
                column: "SubjectId");

            migrationBuilder.CreateIndex(
                name: "IX_students_ClassId_RollNo",
                table: "students",
                columns: new[] { "ClassId", "RollNo" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_subjects_Name",
                table: "subjects",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_teaching_assignments_ClassId_SubjectId",
                table: "teaching_assignments",
                columns: new[] { "ClassId", "SubjectId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_teaching_assignments_SubjectId",
                table: "teaching_assignments",
                column: "SubjectId");

            migrationBuilder.CreateIndex(
                name: "IX_teaching_assignments_TeacherId",
                table: "teaching_assignments",
                column: "TeacherId");

            migrationBuilder.CreateIndex(
                name: "IX_users_LoginId",
                table: "users",
                column: "LoginId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "marks");

            migrationBuilder.DropTable(
                name: "teaching_assignments");

            migrationBuilder.DropTable(
                name: "students");

            migrationBuilder.DropTable(
                name: "subjects");

            migrationBuilder.DropTable(
                name: "classes");

            migrationBuilder.DropTable(
                name: "users");
        }
    }
}
