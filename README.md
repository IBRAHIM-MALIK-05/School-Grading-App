# School Grading App

A school result-management system: **Flutter app → ASP.NET Core Web API (.NET 10) → MySQL**.

| Folder | What it contains |
|---|---|
| `mobile/` | Flutter app (Admin, Teacher / Class Teacher, Principal-VP) |
| `api/` | ASP.NET Core Web API (Visual Studio `.slnx`, EF Core code-first) |
| `database/` | SQL exports from phpMyAdmin (local XAMPP → cloud) |
| `postman/` | Postman collection + environments for API testing |
| `docs/` | Report, User Manual, PowerPoint, screenshots, [database guide (local + cloud)](docs/DATABASE_GUIDE_LOCAL_AND_CLOUD.md) |

## Demo logins (password `123` for all)
| Login ID | Role |
|---|---|
| `admin@school.com` | Admin (use **Login as Admin** on the login screen) |
| `vp@school.com` | Principal / VP |
| `sania@school.com` | Teacher (Chemistry, Biology) + Class Teacher of 8-B |
| `ahsan@school.com` | Teacher (English) + Class Teacher of 8-A |
| `maryam@school.com` | Teacher (Mathematics) + Class Teacher of 9-A |
| `usman@school.com` | Teacher (Physics) + Class Teacher of 9-B |

## Who can do what
| Action | Admin | Class Teacher (own class) | Subject Teacher | Principal / VP |
|---|---|---|---|---|
| Create / edit accounts (Subject → Class duties), reset passwords | ✓ | | | |
| Create / edit classes (name, Class Teacher, subjects + teachers) | ✓ | | | |
| Add / rename subjects, delete unused subjects | ✓ | | | |
| Delete teachers / classes (soft delete: hidden, kept in MySQL) | ✓ | | | |
| Add / delete students (no editing – delete and add again) | ✓ | ✓ | ✗ 403 | |
| Enter marks, Save Progress, Review & Submit | | (own subjects) | ✓ | |
| Class tracker + result-card readiness | ✓ (view) | ✓ | | ✓ (view) |
| Result card | ✓ (view) | ✓ + **Print / Save PDF** | ✗ 403 | ✓ (view) |
| Publish / unpublish results | | ✓ | | |
| Set / change / clear the **Result Date** | ✗ 403 | ✗ 403 | ✗ 403 | ✓ |
| **Notify** the teacher of a pending subject | ✗ 403 | ✓ | ✗ 403 | ✗ 403 |
| Notification Bell + automatic Result Date reminders | | ✓ | ✓ | |

**Two login screens:** Teachers and the Principal / VP use the default *Teacher / Vice Principal
Login*; the Admin taps **Login as Admin**. The API refuses an account on the wrong screen (403),
so nobody gets in through the wrong door. The **Admin Panel** has three tabs – Users, Classes,
Subjects – each with a search bar, and every form uses search-as-you-type pickers.

**Soft delete / hard delete** (same names as the Assignment 2 Web API: `isDeleted`,
`SoftDeleteById`, `HardDeleteById`). The Admin's **Delete** button on a teacher or class only
sets `isDeleted = 1`: the row stays in MySQL, but EF Core's query filter hides it everywhere
(lists, pickers, login, old tokens get 401). A teacher who still leads a class or teaches
subjects must hand them over first (409); the Admin cannot delete their own account (400).
The backend maintainer has extra Admin-only endpoints in **Swagger only** – the app never calls them:

| Endpoint (`users` or `classes`) | What it does |
|---|---|
| `DELETE /api/users/SoftDeleteById?id=` | soft delete (used by the app) |
| `GET /api/users/GetDeleted` | list the soft-deleted rows |
| `PUT /api/users/RestoreById?id=` | undo a soft delete |
| `DELETE /api/users/HardDeleteById?id=` | remove the row for ever – refused (409) while marks or other rows still point to it |

**Notifications (own backend + `flutter_local_notifications`, no Firebase).** Two new tables
(`school_settings`, `notifications`, migration `AddNotifications`):
- The **Principal / VP** sets the *Result Date* on the dashboard (calendar; a past date = 400).
- Every teacher sees it as a banner and has a **Notification Bell** with a red unread badge.
  The app asks `GET /api/notifications` at login and every 30 seconds.
- **Automatic reminders need no cron job** (the free Azure F1 sleeps). Each time a teacher's
  app asks, the server counts the days left and adds a reminder if one is due:
  - 7 days → `deadline_one_week`;
  - 6–3 days → `deadline_daily`;
  - 2–0 days → red `deadline_urgent`.

  A teacher gets at most one reminder per type per day, and only while they still have
  unsubmitted marks. Their last *Submit* marks the unread reminders as read, and their
  Result Date banner turns green: "all your marks are submitted".
- On **My Class** the Class Teacher presses **Notify** next to a pending subject. That
  subject teacher gets a *"Marks Reminder — Class 8 - B (Physics)"* with an optional note.
  The same subject cannot be nudged again while the last reminder is unread (429, 60 min).
  When that teacher submits the subject, the reminder is marked as read by itself.
- New unread notifications pop up as a real phone / Windows / browser alert. On the web,
  permission is asked only after a click on *Enable Desktop/Browser Alerts*; `zonedSchedule`
  is never used. If alerts are blocked, the bell and the in-app message still work.

| Endpoint | Who | What it does |
|---|---|---|
| `GET /api/settings/result-date` | everyone | date, days left, the school's "today" (Pakistan time) |
| `PUT /api/settings/result-date` | VP only | `{ "resultDate": "2026-12-03" }` or `null` to clear |
| `GET /api/notifications` | everyone | runs the deadline check (teachers), then `{ unreadCount, resultDate, daysRemaining, items }` |
| `POST /api/notifications/remind` | Class Teacher of that class | `{ "assignmentId": 8, "message": "optional note" }` → 201 |
| `PUT /api/notifications/{id}/read` | owner | mark one as read (someone else's = 404) |
| `PUT /api/notifications/read-all` | owner | mark all as read |

Deleting a student removes them and all their marks from every subject of the class; the
subject teachers then see *"… was removed by the Class Teacher of …"* on their marks screen.
A sample printed result card is in `docs/samples/result_card_sample.pdf`
(made by `flutter test test/report_card_pdf_test.dart`); screenshots of these features are
`docs/screenshots/m7b_*.png` (`tools/screenshots/capture_m7b_features.py`); the login and
Admin Panel screens are `m7c_*.png` (`tools/screenshots/capture_m7c_admin.py`); soft / hard
delete is `m7d_*.png` (`tools/screenshots/capture_m7d_delete.py`); the Result Date and
notifications are `m7e_*.png` (`tools/screenshots/capture_m7e_notifications.py`).

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

## Cloud API (Azure App Service)
- Live: **https://school-grading-api-bcgi.azurewebsites.net/swagger** (HTTPS only).
- App Service plan `plan-school-grading`: Linux, **Free F1** ($0). Web app `school-grading-api-bcgi`, .NET 10.
  Created with `tools/azure/create_azure_api.py` (settings in `tools/azure/azure_api_resources.json`).
- Secrets are **App Settings on Azure** (environment variables), never in git:
  `ConnectionStrings__DefaultConnection` (Azure MySQL, `SslMode=Required`) and `Jwt__Key`.
  New JWT key at any time: `python tools/azure/create_azure_api.py --rotate-jwt`.
- **CI/CD:** `.github/workflows/deploy-api.yml` – every push to `main` that changes `api/**`
  builds the API and deploys it (GitHub secret `AZURE_WEBAPP_PUBLISH_PROFILE`).
- The free F1 plan sleeps when idle: the first request after a break can take 20–30 s.
- The cloud database must be **started** for the API to work (see above).

## Test the API (Postman / Newman)
- Local: with the API running, double-click `postman/run_tests_local.cmd`.
- Azure: double-click `postman/run_tests_azure.cmd` (wakes the server up first).
- Both run 200 requests / 399 tests and write an HTML report to `postman/reports/`
  (login tokens are removed from the report by `postman/redact_tokens.js`).
  Or import the JSON files in `postman/` into the Postman app and pick the *Local* or *Azure* environment.
- Afterwards, reset the cloud data: `python tools/azure/import_to_azure.py --reset`.

## Run the app
The app talks to the **live Azure API** by default.
```bash
cd mobile
flutter pub get
flutter run -d chrome
```
The server address is one line in `mobile/lib/services/api_config.dart`:
Azure `https://school-grading-api-bcgi.azurewebsites.net/api` (current),
local `http://localhost:5080/api`, Android emulator + local API `http://10.0.2.2:5080/api`.

## Milestones (git tags)
- `v0-original` – the original prototype (mock data, 5 screens)
- `v1-mock-ui` – full multi-role UI on mock data
- `v2-local-db` – `school_grading` database in XAMPP + design
- `v3-azure-db` – the same database on Azure Database for MySQL Flexible Server (8.4, B1ms)
- `v4-local-api` – ASP.NET Core Web API (.NET 10, EF Core code-first, JWT) on XAMPP MySQL
- `v5-postman-tests` – Postman collection (52 requests, 113 tests) + Newman HTML report
- `v6-azure-api` – API on Azure App Service (F1) with GitHub Actions CI/CD; Postman + Flutter against Azure
- `v7-live-flutter` – Flutter app on the real API + MySQL (mock data removed)
