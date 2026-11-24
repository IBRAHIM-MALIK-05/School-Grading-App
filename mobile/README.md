# School Grading App – Flutter client

The mobile/web app of the School Grading System. Every screen gets its data from the
ASP.NET Core Web API (`../api`), which stores it in MySQL (XAMPP locally, Azure in the cloud).

| Role | What the app lets them do |
|---|---|
| Admin | Create Teacher / Principal-VP accounts, reset passwords, manage students |
| Teacher | Enter, save and submit marks for their own subjects |
| Class Teacher | Track which subjects are submitted, view result cards, publish results |
| Principal / VP | School overview and class grading status (read-only) |

## Run
```bash
flutter pub get
flutter run -d chrome        # or an Android emulator
```

## Where things are
- `lib/services/api_config.dart` – the API address (one line): Azure, `http://localhost:5080/api`,
  or `http://10.0.2.2:5080/api` for an Android emulator with the local API.
- `lib/services/api_data_service.dart` – all HTTP calls (JWT, timeout, error messages).
- `lib/models/` – data classes with `fromJson`.
- `lib/screens/` – the screens, grouped by role (`admin/`, `teacher/`, `vp/`, `shared/`).

Demo logins (password `123`): `admin@school.com`, `vp@school.com`, `sania@school.com`.
See the main [README](../README.md) for the whole project.
