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

## Run the app
```bash
cd mobile
flutter pub get
flutter run -d chrome
```

## Milestones (git tags)
- `v0-original` – the original prototype (mock data, 5 screens)
- `v1-mock-ui` – full multi-role UI on mock data
- `v2-local-db` – `school_grading` database in XAMPP + design
- `v4-local-api` – ASP.NET Core Web API (.NET 10, EF Core code-first, JWT) on XAMPP MySQL
