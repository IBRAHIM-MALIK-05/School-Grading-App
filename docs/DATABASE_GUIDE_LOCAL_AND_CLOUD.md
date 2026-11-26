# Database guide: local (XAMPP) and cloud (Azure)

A step-by-step guide for running the School Grading App on the **local** database (XAMPP,
works with no internet) and on the **cloud** database (Azure), plus what is the same and what
is different. Written for the viva.

**Contents:**
- [Part A: Local database (XAMPP), works with no internet](#part-a-local-database-xampp-works-with-no-internet)
- [Part B: Cloud database (Azure), needs internet](#part-b-cloud-database-azure-needs-internet)
- [Part C: What's the same in both, and what's different](#part-c-whats-the-same-in-both-and-whats-different)
- [Likely viva questions, with short answers](#likely-viva-questions-with-short-answers)

---

## Part A: Local database (XAMPP), works with no internet

Everything here runs on the laptop. The only parts that need internet are the Gmail-draft
button and `git push`.

### Already installed (nothing to download)
- **XAMPP**: MariaDB 10.4.32 as the database server, phpMyAdmin, and Apache (only needed for phpMyAdmin).
- **.NET 10 SDK**, with the API's NuGet packages and the `dotnet-ef` tool already saved on the laptop.
- **Flutter SDK** and Chrome or Edge.
- **Newman** (the command-line Postman runner) in `tools\node` and `tools\postman-runner`.

### Steps
1. **Start the database.** Open the XAMPP Control Panel and press **Start** next to **MySQL**
   (it uses port 3306).
   - Also start **Apache** if you want phpMyAdmin at `http://localhost/phpmyadmin`.
2. **First time only, or to reset to clean demo data.** Run these from the project folder:
   ```
   d:\xampp\mysql\bin\mysql.exe -u root -e "DROP DATABASE IF EXISTS school_grading;"
   type database\01_create_database.sql | d:\xampp\mysql\bin\mysql.exe -u root
   cd api\SchoolGradingApi
   dotnet ef database update
   ```
   - In Visual Studio, `dotnet ef database update` is **Package Manager Console → `Update-Database`**.
   - It applies the **4 migrations**: `InitialCreate`, `AddStudentRemovals`, `AddSoftDelete`,
     `AddNotifications`.
   - It creates the **9 tables** and the demo data: 6 users, 5 subjects, 5 classes,
     25 students, 25 teaching assignments, 47 marks, and 1 settings row (no Result Date yet).
   - Stop the API first if it is running: a running API locks its build files, and the update
     then fails with "Build failed".
3. **Run the API.** Either:
   - open `api\SchoolGrading.slnx` in Visual Studio and press **Run (http)**, or
   - run `cd api\SchoolGradingApi` then `dotnet run --launch-profile http`.

   Swagger opens at **http://localhost:5080/swagger**. Swagger is built into the API, so it
   works offline.
   - The API reads `ConnectionStrings:DefaultConnection` from `appsettings.json`:
     `server=localhost;port=3306;database=school_grading;user=root;password=;`
   - The local JWT key is in `appsettings.Development.json`. The "http" profile runs in the
     Development environment.
4. **Point the app at the local API.** In `mobile\lib\services\api_config.dart`, change the one line to:
   - Chrome or Edge: `'http://localhost:5080/api'`
   - Android emulator: `'http://10.0.2.2:5080/api'` (`10.0.2.2` means "the laptop" from inside the emulator)

   ⚠️ Change it back to the Azure URL before you commit or build the release.
5. **Run the app offline:**
   ```
   cd mobile
   flutter run -d chrome --no-web-resources-cdn
   ```
   - `--no-web-resources-cdn` loads Flutter's web rendering engine from the laptop instead of
     Google's servers.
   - If `flutter pub get` complains, use `flutter pub get --offline`.
   - Without internet, text may show in a slightly different system font, because Flutter web
     normally downloads its font from Google. The app still works.
   - The Notification Bell, Result Date and pop-up alerts also work offline: they come from
     our own API, not from Firebase.
6. **Test.** Double-click `postman\run_tests_local.cmd`. Newman runs **200 requests and 399
   tests** offline.
   - The Postman desktop app may ask you to sign in; Newman never does.
7. **Look at the data:**
   - phpMyAdmin (needs Apache), or
   - DBeaver connected to `localhost:3306`, user `root`, no password, database `school_grading`.
8. **Finish.** Press Ctrl+C in the API window (or stop it in Visual Studio), then **Stop**
   MySQL in XAMPP.

### If something goes wrong locally
| Problem | Cause and fix |
|---|---|
| API says "Unable to connect to any of the specified MySQL hosts" | MySQL isn't started in XAMPP. |
| XAMPP MySQL won't start | Port 3306 is used by another MySQL program. Stop that one. |
| `Update-Database` says "Build failed" | The API is still running and locks its files. Stop it, then run the update again. |
| `Update-Database` crashed on XAMPP | MariaDB 10.4 answers one EF Core migration-lock command differently. `database\MariaDbFix.cs` (an EF Core interceptor) fixes only that command, and only matters locally. |

---

## Part B: Cloud database (Azure), needs internet

### Steps
1. **Start the database server.** Either:
   - Azure Portal (Brave profile) → `school-grading-mysql-bcgi` → **Start**, or
   - `tools\azure-cli\bin\az.cmd mysql flexible-server start -g rg-school-grading -n school-grading-mysql-bcgi`

   Wait until the state is **Ready** (a few minutes).
2. **Firewall** (only on a new network, e.g. university Wi-Fi): Portal → server →
   **Networking** → **Add current client IP address** → **Save**.
   - The home networks are the rules `HomeInternet1`–`4`.
   - The rule `AllowAllAzureServicesAndResourcesWithinAzureIps` lets the App Service (the API)
     reach the database.
   - Don't show the Networking page in slides: it shows your IP address.
3. **Wake the API.** Open **https://school-grading-api-bcgi.azurewebsites.net/swagger**.
   - The free F1 plan sleeps when idle, so the first request takes 20–30 s.
   - The API is already deployed: every push that changes `api/**` makes GitHub Actions
     rebuild and deploy it.
4. **Run the app.** `api_config.dart` already points at Azure, so just run `cd mobile` then
   `flutter run -d chrome`.
5. **View the data in DBeaver:**
   - Host `school-grading-mysql-bcgi.mysql.database.azure.com`, port 3306, database
     `school_grading`, user `gradingadmin`.
   - The password is in the git-ignored file `tools\azure\azure_mysql.local.json`.
   - **SSL tab:** tick *Use SSL* and *Require SSL*; untick *Verify server certificate* and
     *Allow public key retrieval*.
6. **Test.** Double-click `postman\run_tests_azure.cmd` (200 requests, 399 tests).
   - The very first request after the API wakes up can fail the "under 3 seconds" check.
     Run it once more when the API is awake.
7. **Reset the cloud data.** XAMPP MySQL must be running too, because the script compares the
   two:
   `tools\.venv\Scripts\python -I tools\azure\import_to_azure.py --reset`
   - It imports `database\03_school_grading_export_for_azure.sql` over an encrypted
     connection, checking the server's certificate.
   - It then compares the row counts of all 9 tables with XAMPP and prints
     `ALL TABLES MATCH`.
   - Reset XAMPP to clean demo data first (Part A, step 2), or the counts will differ.
8. **Stop the server** when you're finished: Portal → **Stop**, or the same `az` command with
   `stop`. This saves free hours. Azure restarts a stopped server by itself after 30 days.

### Where the cloud settings live
On the App Service, under **Environment variables** (never in git):
- `ConnectionStrings__DefaultConnection`: the Azure host, `gradingadmin`, its password, and
  `SslMode=Required`.
- `Jwt__Key`: a different key from the local one. Rotate it with
  `create_azure_api.py --rotate-jwt`; every token issued before that gets 401.
- `ASPNETCORE_ENVIRONMENT`.

The double underscore `__` means `:`. So `ConnectionStrings__DefaultConnection` overrides
`ConnectionStrings:DefaultConnection` in `appsettings.json`. That is why **the same code** works
locally and on Azure.

### How data moved from local to cloud
The design was made in XAMPP first, exported with phpMyAdmin as `03_…_export_for_azure.sql`,
then imported into Azure (originally in Milestone 3; today with `import_to_azure.py`).

When the database design changes:
1. Add an EF migration and apply it locally.
2. Update the export file. I check it by importing it into a test database and comparing
   columns, indexes, foreign keys and rows table by table with XAMPP. Both `isDeleted` and the
   notification tables were added this way.
3. Run `--reset` to bring Azure to the same state.

---

## Part C: What's the same in both, and what's different

### The same in both (expect viva questions here)
| Item | Value |
|---|---|
| Database name | `school_grading` |
| Character set / collation | `utf8mb4` / `utf8mb4_general_ci`: full Unicode, case-insensitive, and the same on MariaDB and MySQL 8 |
| Tables (9) | `users`, `subjects`, `classes`, `students`, `teaching_assignments`, `marks`, `student_removals`, `school_settings`, `notifications`, plus `__EFMigrationsHistory` |
| Keys and rules | Same 10 primary keys, 14 foreign keys (with CASCADE / RESTRICT / SET NULL) and unique indexes. Soft-delete column `isDeleted` on `users` and `classes`. |
| Migrations (4) | `InitialCreate`, `AddStudentRemovals`, `AddSoftDelete`, `AddNotifications` |
| Demo data | 6 users, 5 subjects, 5 classes, 25 students, 25 teaching assignments, 47 marks, 1 settings row, 0 notifications. Password `123` for every demo login. |
| Port / protocol | 3306, the MySQL protocol |
| API code | ASP.NET Core Web API (.NET 10), EF Core 10 code-first, Oracle's `MySql.EntityFrameworkCore` (`UseMySQL`), one connection string named `DefaultConnection` |
| Security | BCrypt password hashes; JWT logins (issuer `SchoolGradingApi`, audience `SchoolGradingApp`, valid 8 h) |
| Notifications | Own backend (no Firebase). Reminders are made on demand when a teacher's app asks, not by a cron job. The school's "today" uses Pakistan time (UTC+5) on both. |
| Testing | One Postman collection (200 requests, 399 tests). Only the environment's `baseUrl` changes. |
| Flutter app | The same app; only `apiBaseUrl` in `api_config.dart` changes |

### What's different
| | Local (XAMPP) | Cloud (Azure) |
|---|---|---|
| Server software | MariaDB 10.4.32 | Azure Database for MySQL Flexible Server, MySQL 8.4 |
| Size / region | The laptop | Burstable B1ms, 20 GB, Korea Central, 7-day backups, no high availability |
| Host / user | `localhost`, `root`, no password | `…mysql.database.azure.com`, `gradingadmin`, password in a git-ignored file |
| Encryption | None (never leaves the laptop) | TLS required (`SslMode=Required`) |
| Who can connect | Only this laptop | Firewall rules: your IPs plus Azure services |
| API address | `http://localhost:5080` | `https://school-grading-api-bcgi.azurewebsites.net` (App Service F1, Linux, HTTPS only) |
| Where settings live | `appsettings.json` and `appsettings.Development.json` | App Service environment variables |
| How tables were made | `dotnet ef database update` (migrations) | Import of the phpMyAdmin export SQL |
| Tools | XAMPP Control Panel, phpMyAdmin, DBeaver | Azure Portal, `az` CLI, DBeaver (SSL) |
| Special fix | `MariaDbFix.cs` (needed only for MariaDB) | Not needed |
| Cost | Free | Inside the free student allowance (750 h + 32 GB); $1 budget alert; stop it when idle |
| Internet | Not needed | Needed |
| Small detail | Shows `int(11)` | Shows `int` (same type; MySQL 8 just stopped showing the width) |

---

## Likely viva questions, with short answers
- **Why didn't the API code change between local and cloud?**
  Only the connection string changes. On Azure it comes from an environment variable that
  overrides `appsettings.json`.
- **Why is TLS required on Azure but not locally?**
  On Azure, data travels over the internet; locally it never leaves the laptop.
- **What is a migration?**
  C# code that EF Core generates to create or change tables. `__EFMigrationsHistory` records
  which ones have already run.
- **Why stop the Azure server?**
  It saves free hours. The API can't reach a stopped database, so logins fail until it is
  started again.
- **How is a deleted teacher still "in the database"?**
  Soft delete only sets `isDeleted = 1`. EF Core's query filter hides those rows, and
  `GetDeleted` / `RestoreById` can see and undo it.
- **How do automatic Result Date reminders work without a cron job?**
  The free Azure F1 sleeps, so a timer on the server would not run. Instead, every time a
  teacher's app asks `GET /api/notifications` (at login and every 30 s), the server counts the
  days left:
  - 7 days → one-week reminder;
  - 6–3 days → daily reminder;
  - 2–0 days → urgent reminder.

  It saves at most one per teacher, day and type, and only for teachers with unsubmitted marks.
- **Why no Firebase?**
  Our own API and MySQL store the notifications, and the app shows the pop-up itself with
  `flutter_local_notifications`. Nothing depends on Google's services, so it also works on
  XAMPP with no internet.
- **What is in `school_settings`?**
  Exactly one row (`Id = 1`) with the Result Date that only the Principal / VP can set
  (others get 403; a past date gets 400).
