# School Grading App

A school result-management system: **Flutter app → ASP.NET Core Web API (.NET 10) → MySQL**.

| Folder | What it contains |
|---|---|
| `mobile/` | Flutter app (Admin, Teacher / Class Teacher, Principal-VP) |
| `api/` | ASP.NET Core Web API (Visual Studio `.slnx`, EF Core code-first) |
| `database/` | SQL exports from phpMyAdmin (local XAMPP → cloud) |
| `postman/` | Postman collection + environments for API testing |
| `docs/` | Report, User Manual, PowerPoint, screenshots |

## Demo logins (password `123` for all)
| Login ID | Role |
|---|---|
| `admin@school.com` | Admin |
| `vp@school.com` | Principal / VP |
| `sania@school.com` | Teacher (Chemistry, Biology) + Class Teacher of 8-B |
| `ahsan@school.com` | Teacher (English) + Class Teacher of 8-A |
| `maryam@school.com` | Teacher (Mathematics) + Class Teacher of 9-A |
| `usman@school.com` | Teacher (Physics) + Class Teacher of 9-B |

## Run the API (local)
1. Start **Apache + MySQL** in the XAMPP Control Panel (database `school_grading`).
2. Open `api/SchoolGrading.slnx` in Visual Studio and press **Run (http)**  
   – or: `cd api/SchoolGradingApi` → `dotnet run --launch-profile http`
3. Swagger opens at **http://localhost:5080/swagger**.  
   Login with `POST /api/auth/login`, then press **Authorize** and paste the token.

First time only (creates the tables + demo data): Visual Studio → *Package Manager Console* →
`Update-Database`  (or `dotnet tool restore` then `dotnet ef database update` in `api/SchoolGradingApi`).

## Cloud database (Azure Database for MySQL)
- Server `school-grading-mysql-bcgi` in resource group `rg-school-grading` (Korea Central):
  MySQL 8.4, Burstable **B1ms**, 20 GB (auto-grow off, auto-scale IOPS off), no HA,
  7-day locally-redundant backups — all inside the Azure free allowance (750 h + 32 GB), with a $1 budget alert.
- Created with the Azure CLI: `tools/azure/create_azure_mysql.py` (settings in `tools/azure/azure_resources.json`).
- Data: phpMyAdmin export `database/03_school_grading_export_for_azure.sql`, imported and checked
  row-for-row against XAMPP by `tools/azure/import_to_azure.py` (TLS, certificate verified).
- The admin password lives only in the git-ignored `tools/azure/azure_mysql.local.json`.
- **Save free hours:** Portal → the server → **Stop** when not testing, **Start** before a demo
  (Azure starts a stopped server again by itself after 30 days).

## Test the API (Postman / Newman)
With the API running: double-click `postman/run_tests_local.cmd` → 52 requests, 113 tests,
HTML report in `postman/reports/`. Or import the two JSON files in `postman/` into the Postman app.

## Run the app
The app talks to the real API, so start XAMPP MySQL and the API first (see above).
```bash
cd mobile
flutter pub get
flutter run -d chrome
```
The server address is one line in `mobile/lib/services/api_config.dart`
(`http://localhost:5080/api`; Android emulator: `http://10.0.2.2:5080/api`).

## Milestones (git tags)
- `v0-original` – the original prototype (mock data, 5 screens)
- `v1-mock-ui` – full multi-role UI on mock data
- `v2-local-db` – `school_grading` database in XAMPP + design
- `v3-azure-db` – the same database on Azure Database for MySQL Flexible Server (8.4, B1ms)
- `v4-local-api` – ASP.NET Core Web API (.NET 10, EF Core code-first, JWT) on XAMPP MySQL
- `v5-postman-tests` – Postman collection (52 requests, 113 tests) + Newman HTML report
- `v7-live-flutter` – Flutter app on the real API + MySQL (mock data removed)
