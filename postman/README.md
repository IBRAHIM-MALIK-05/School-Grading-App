# API tests (Postman + Newman)

| File | What it is |
|---|---|
| `SchoolGrading.postman_collection.json` | 52 requests in 7 folders, each with test scripts (113 checks in total) |
| `SchoolGrading_Local.postman_environment.json` | `baseUrl = http://localhost:5080/api` (an **Azure** environment is added at deployment) |
| `run_tests_local.cmd` | Runs the whole collection with **Newman** and writes the HTML report |
| `reports/local_test_report.html` | Latest HTML report (open in a browser) |
| `reports/local_cli_output.txt` | The same run as plain text |

## Run in the Postman app
1. Postman → **Import** → select both JSON files.
2. Top-right: choose the environment **School Grading - Local**.
3. Start the API (Visual Studio → Run, *http* profile) and XAMPP MySQL.
4. Right-click the collection → **Run collection** → **Run School Grading API**.

The folders run in order. The *Login* requests save the JWT tokens into collection
variables (`adminToken`, `saniaToken`, …), so every later request is sent with
`Authorization: Bearer <token>` automatically.

## Run from the command line (Newman)
Double-click `run_tests_local.cmd` (or run it in a terminal). It uses the portable
Node.js in `tools/node` and Newman in `tools/postman-runner` – nothing is installed globally.

## What the folders test
1. **Auth – Login:** every role logs in; wrong password → 401.
2. **Create account & first login:** Admin registers a teacher (201, Login ID + temporary
   password); errors 400/401/403/409; the new teacher is blocked (403) until they change
   the temporary password; weak / wrong passwords → 400.
3. **Users & password reset:** only Admin lists users; reset gives a new temporary
   password and the old one stops working (401).
4. **Classes, tracker & students:** overview, live submission tracker, publish blocked while
   subjects are pending (409), add student (201) / duplicates (409) / empty name (400);
   adding a student clears the submissions.
5. **Marks:** a teacher's subjects; marks above the maximum (400); submit with a missing
   mark (400); full submit (200); another teacher's subject (403).
6. **Result cards & delete student:** complete vs incomplete result card; delete (200/404).
7. **Publish & lock:** Class Teacher publishes 9-A; adding students / saving marks in a
   locked class → 409; only the Class Teacher may publish (403); unpublish again.

The collection cleans up after itself (deletes the student it adds, unpublishes 9-A),
so it can be run again and again. Each run adds one new teacher account (`ali@school.com`,
`ali2@school.com`, …).
