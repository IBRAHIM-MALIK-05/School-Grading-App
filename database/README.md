# Database design – `school_grading` (MySQL / MariaDB)

**Where it runs**
| Stage | Server | Tool |
|---|---|---|
| Local (Milestone 2) | XAMPP → MariaDB 10.4.32 on `localhost:3306`, user `root` (no password) | phpMyAdmin `http://localhost/phpmyadmin` |
| Cloud (later) | Azure Database for MySQL 8 (Flexible Server) | DBeaver |

**Character set / collation:** `utf8mb4` / `utf8mb4_general_ci` – full Unicode,
case-insensitive (so `Sania@School.com` and `sania@school.com` match), and
identical on MariaDB and MySQL 8 so the phpMyAdmin export imports into Azure
without errors.

**How the tables are created:** *code-first*. Each table below is a C# class in
the API (`entities/`), configured in `AppDbContext` (`modelBuilder…`), and
created by `Update-Database` (EF Core migrations) in Milestone 4. The demo rows
are added with `HasData(...)` – the same data the Flutter mock (`DummyDB`) uses.

**Naming:** table names are lower-case `snake_case` (`teaching_assignments`),
column names are the C# property names (`FullName`, `ClassId`) – the EF Core
default. MySQL column names are case-insensitive.

---

## The 6 tables

### 1. `users` – everyone who can log in
| Column | Type | Rules |
|---|---|---|
| `Id` | int | **PK**, auto-increment |
| `FullName` | varchar(100) | required |
| `LoginId` | varchar(100) | required, **UNIQUE**, never changes (e.g. `sania@school.com`) |
| `ContactEmail` | varchar(150) | optional – real Gmail used to send login details |
| `PasswordHash` | varchar(100) | required – **BCrypt hash**, never the plain password |
| `Role` | varchar(20) | `admin`, `teacher` or `vp` |
| `MustChangePassword` | tinyint(1) | 1 = temporary password, must change at next login |
| `CreatedAt` | datetime(6) | when the account was created |
| `isDeleted` | tinyint(1) | **soft delete**: 1 = deleted by the Admin (hidden, cannot log in), row kept |

### 2. `subjects`
| Column | Type | Rules |
|---|---|---|
| `Id` | int | **PK** |
| `Name` | varchar(50) | required, **UNIQUE** (English, Mathematics, Physics, Chemistry, Biology) |
| `MaxMarks` | int | 100 or 60 |

### 3. `classes` – a class + section, e.g. Class 8 - B
| Column | Type | Rules |
|---|---|---|
| `Id` | int | **PK** |
| `GradeName` | varchar(20) | e.g. `Class 8` |
| `Section` | varchar(5) | e.g. `B` |
| `ClassTeacherId` | int | **FK → users.Id**, optional, **UNIQUE** (a teacher leads at most one class), `ON DELETE SET NULL` |
| `ResultsPublishedAt` | datetime(6) | NULL = not published. Not NULL = published → marks & students **locked** |
| `isDeleted` | tinyint(1) | **soft delete**: 1 = deleted by the Admin (hidden), students + marks kept |
| | | **UNIQUE (`GradeName`, `Section`)** – no duplicate "Class 8 - B" |

### 4. `students`
| Column | Type | Rules |
|---|---|---|
| `Id` | int | **PK** |
| `FullName` | varchar(100) | required |
| `RollNo` | varchar(10) | `01`, `02`, … |
| `ClassId` | int | **FK → classes.Id**, `ON DELETE RESTRICT` (cannot delete a class that still has students) |
| | | **UNIQUE (`ClassId`, `RollNo`)** – roll numbers unique inside a class |

### 5. `teaching_assignments` – *who teaches which subject in which class*
| Column | Type | Rules |
|---|---|---|
| `Id` | int | **PK** |
| `ClassId` | int | **FK → classes.Id** |
| `SubjectId` | int | **FK → subjects.Id** |
| `TeacherId` | int | **FK → users.Id** |
| `SubmittedAt` | datetime(6) | NULL = not submitted yet; set when the teacher presses **Submit** |
| | | **UNIQUE (`ClassId`, `SubjectId`)** – exactly one teacher per subject per class |

This table is what powers the **Class Teacher's live submission tracker**:
for each subject of a class it tells us the teacher, and whether they submitted.

### 6. `marks`
| Column | Type | Rules |
|---|---|---|
| `Id` | int | **PK** |
| `StudentId` | int | **FK → students.Id**, `ON DELETE CASCADE` (deleting a student deletes their marks) |
| `SubjectId` | int | **FK → subjects.Id** |
| `Obtained` | int | 0 … subject's `MaxMarks` (checked by the API) |
| `EnteredById` | int | **FK → users.Id** – which teacher entered it |
| `UpdatedAt` | datetime(6) | last time it was saved |
| | | **UNIQUE (`StudentId`, `SubjectId`)** – one mark per student per subject |

---

## Relationships (ERD)

```mermaid
erDiagram
    users ||--o{ teaching_assignments : "teaches"
    users |o--o| classes : "is class teacher of"
    users ||--o{ marks : "entered"
    classes ||--o{ students : "has"
    classes ||--o{ teaching_assignments : "has subjects"
    subjects ||--o{ teaching_assignments : "taught in"
    subjects ||--o{ marks : "for"
    students ||--o{ marks : "gets"
```

In words:
* A **class** has many **students** (1 → many).
* A **class** has 5 **teaching assignments** (one per subject); each links a
  **subject** and a **teacher** (many ↔ many between classes, subjects and
  teachers, resolved by this "junction" table).
* A **student** has one **mark** per **subject** (many ↔ many between students
  and subjects, resolved by `marks`).
* A **class** has at most one **class teacher**, and a teacher is class teacher
  of at most one class (1 ↔ 1, optional).

## Rules the database itself enforces
| Rule | How |
|---|---|
| No two users with the same Login ID | UNIQUE `users.LoginId` |
| One teacher per subject per class | UNIQUE (`ClassId`, `SubjectId`) |
| One mark per student per subject | UNIQUE (`StudentId`, `SubjectId`) |
| Roll numbers unique inside a class | UNIQUE (`ClassId`, `RollNo`) |
| A mark always belongs to a real student/subject | Foreign keys |
| Deleting a student removes their marks | `ON DELETE CASCADE` |

Business rules (marks between 0 and max, "cannot edit a published class",
"only the class teacher can publish", password rules…) are checked in the
**API controllers**, because they depend on who is logged in.

## Demo data (seeded in Milestone 4 – same as the Flutter mock)
* **Users** (password `123` for all, stored as BCrypt hashes):
  `admin@school.com` (Admin), `vp@school.com` (VP Sarah),
  `sania@school.com`, `ahsan@school.com`, `maryam@school.com`, `usman@school.com` (Teachers)
* **Subjects:** English 100, Mathematics 100, Physics 60, Chemistry 60, Biology 60
* **Classes:** 8-A (CT Ahsan), 8-B (CT Sania), 9-A (CT Maryam), 9-B (CT Usman), 9-C (none)
* **Teaching assignments:** every class has all 5 subjects
  (English Ahsan, Maths Maryam, Physics Usman, Chemistry + Biology Sania) = 25 rows
* **Students:** 5 per class = 25 (8-B: Sarah, Ahmed, Zain, Fatima, Bilal)
* **Marks:** 8-A Chemistry submitted; 8-B English/Maths/Biology submitted,
  Physics + Chemistry in progress; 9-A all 5 submitted (ready to publish).

## Files in this folder
| File | Purpose |
|---|---|
| `01_create_database.sql` | Creates the empty database with the right collation (same as the phpMyAdmin step) |
| `README.md` | This design document |
| `02_initial_create_generated_by_ef.sql` | The SQL that EF Core generated from the C# entities (what Update-Database ran) – for reading only |
| `03_school_grading_export_for_azure.sql` | phpMyAdmin export used to migrate to Azure (Milestone 3); `student_removals` was added to it later so XAMPP and Azure stay identical |
| `04_add_student_removals_generated_by_ef.sql` | SQL of the 2nd migration `AddStudentRemovals` (one new table, see below) – for reading only |
| `05_add_soft_delete_generated_by_ef.sql` | SQL of the 3rd migration `AddSoftDelete` (`isDeleted` on `users` + `classes`) – for reading only |
| `06_add_notifications_generated_by_ef.sql` | SQL of the 4th migration `AddNotifications` (`school_settings` + `notifications`) – for reading only |

## Later change: `student_removals` (migration `AddStudentRemovals`)
When a Class Teacher (or the Admin) deletes a student, the student row and ALL their marks are
deleted. One small row is kept in `student_removals` (class, student name, roll number, who
removed them, when) so the **subject teachers** of that class see
*"Ali (roll 06) was removed by the Class Teacher of Class 8 - B"* on their marks screen
instead of wondering why the name vanished.

| Column | Type | Notes |
|---|---|---|
| Id | int, PK, auto-increment | |
| ClassId | int, FK → classes.Id | which class |
| StudentName | varchar(100) | copied, because the student row is gone |
| RollNo | varchar(10) | copied |
| RemovedById | int, FK → users.Id | who deleted the student |
| RemovedByRole | varchar(20) | "Class Teacher" or "Admin" |
| RemovedAt | datetime(6) | UTC |

Applied locally with `dotnet ef database update`; on Azure the same table is created by
`tools/azure/import_to_azure.py --reset` (it imports `03_…_export_for_azure.sql`).

## Later change: soft delete (migration `AddSoftDelete`)
Same idea and names as the Assignment 2 Web API (`public bool isDeleted { get; set; }`).
`users` and `classes` got one column `isDeleted tinyint(1) NOT NULL DEFAULT 0`; every demo row
starts at 0. When the Admin deletes a teacher or class in the app, the API only sets it to 1.
`AppDbContext` adds `HasQueryFilter(e => !e.isDeleted)` for both tables, so EF Core writes
`WHERE isDeleted = 0` into every query by itself – deleted rows vanish from lists, pickers and
login without changing any other query. Only the maintainer endpoints (`GetDeleted`,
`RestoreById`, `HardDeleteById`) and the "is this name / Login ID free?" checks use
`.IgnoreQueryFilters()` to see them (the UNIQUE indexes still count deleted rows).
Hard delete (`HardDeleteById`, Swagger only) really removes the row and is refused (409) while
marks, subjects or removal notices still point to it, so results are never lost.

Applied locally with `dotnet ef database update`; the same columns are in
`03_…_export_for_azure.sql` (checked: importing it gives exactly the XAMPP columns, indexes,
foreign keys and rows), so `import_to_azure.py --reset` brings Azure to the same state.

## Later change: Result Date + notifications (migration `AddNotifications`)
Two new tables for the Notification Bell (our own backend, no Firebase):

**`school_settings`**: exactly ONE row (`Id = 1`, not AUTO_INCREMENT).

| Column | Type | Meaning |
|---|---|---|
| `Id` | int, PK | always 1 |
| `ResultDate` | date, NULL | the day results are announced (set by the Principal / VP). NULL = not set |
| `UpdatedByUserId` | int, NULL, FK → `users.Id` (ON DELETE SET NULL) | who changed it last |
| `UpdatedAt` | datetime(6), NULL | when (UTC) |

**`notifications`**: one message in a user's bell.

| Column | Type | Meaning |
|---|---|---|
| `Id` | int, PK, AUTO_INCREMENT | |
| `RecipientUserId` | int, FK → `users.Id` (ON DELETE **CASCADE**) | who gets it (a user removed for ever loses their inbox) |
| `SenderUserId` | int, NULL, FK → `users.Id` (ON DELETE SET NULL) | the Class Teacher; **NULL = automatic system reminder** |
| `Type` | varchar(40) | `class_teacher_reminder`, `deadline_one_week`, `deadline_daily`, `deadline_urgent` |
| `Title`, `Message` | varchar(150), varchar(1000) | the text shown in the app |
| `IsUrgent` | tinyint(1) | 1 = red alert (2 days or less) |
| `IsRead` | tinyint(1), DEFAULT 0 | |
| `CreatedAt` | datetime(6) | UTC |
| `NotificationDate` | date | the school day it was made for |
| `AssignmentId` | int, NULL, FK → `teaching_assignments.Id` (ON DELETE SET NULL) | which subject + class a reminder is about |

Index `(RecipientUserId, NotificationDate, Type)`: the deduplication check, "does this teacher
already have today's reminder of this type?", is a quick index lookup. The API makes at most
one automatic reminder per teacher, day and type, so refreshing the app never creates
duplicates.

`DateOnly` (a date without a time) is stored in a `date` column. Oracle's MySQL provider
reads `date` back as `DateTime`, so `AppDbContext.ConfigureConventions` converts it
(DateOnly ↔ DateTime at midnight).

As with soft delete: applied locally with `dotnet ef database update`. The same tables, the
settings row and the migration-history row are also in `03_…_export_for_azure.sql`. I checked
it by importing it into a test database: the columns, indexes, foreign keys and rows of all
10 tables are the same as XAMPP. `import_to_azure.py --reset` now also compares row counts for
`school_settings` and `notifications`.

## How the tables were created (Milestone 4)
1. `Add-Migration InitialCreate` (CLI: `dotnet ef migrations add InitialCreate`) – EF Core
   compares the entities + `AppDbContext` with an empty database and writes
   `Migrations/…_InitialCreate.cs` (C# code that creates the 6 tables + inserts demo data).
2. `Update-Database` (CLI: `dotnet ef database update`) – runs that migration on XAMPP MySQL
   and records it in the `__EFMigrationsHistory` table, so it is never applied twice.

**XAMPP note:** XAMPP ships **MariaDB 10.4**, not MySQL 8. One command EF uses
before migrating (`GET_LOCK(..., -1)`) behaves differently on MariaDB, so the API
has a tiny EF Core *interceptor* (`api/SchoolGradingApi/database/MariaDbFix.cs`)
that adjusts only that command. Nothing changes on MySQL 8 / Azure.

**Reset to clean demo data:** drop `school_grading`, run `01_create_database.sql`,
then `Update-Database` again.
