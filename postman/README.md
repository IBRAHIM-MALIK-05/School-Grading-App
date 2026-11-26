# API tests (Postman + Newman)

| File | What it is |
|---|---|
| `SchoolGrading.postman_collection.json` | 200 requests in 11 folders, each with test scripts (399 checks in total) |
| `SchoolGrading_Local.postman_environment.json` | `baseUrl = http://localhost:5080/api` |
| `SchoolGrading_Azure.postman_environment.json` | `baseUrl = https://school-grading-api-bcgi.azurewebsites.net/api` (live cloud API) |
| `run_tests_local.cmd` | Runs the whole collection with **Newman** against the local API and writes the HTML report |
| `run_tests_azure.cmd` | The same against **Azure** (wakes up the free F1 server first) |
| `reports/local_test_report.html` | Latest HTML report (open in a browser) |
| `reports/local_cli_output.txt` | The same run as plain text |
| `reports/azure_test_report.html`, `reports/azure_cli_output.txt` | Latest run against Azure (200 requests, 399 tests, 0 failures) |

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
4. **Classes, tracker & students:** overview, live submission tracker + per-student result-card
   readiness (which subject / teacher a card waits for), publish blocked while subjects are
   pending (409), add student (201) / duplicates (409) / empty name, 11-character roll
   `00000000089` or negative roll (400); a **subject teacher** who is not the Class Teacher
   cannot list or add students of that class (403); adding a student clears the submissions.
5. **Marks:** a teacher's subjects; marks above the maximum (400); submit with a missing
   mark (400); full submit (200); another teacher's subject (403).
6. **Result cards & delete student:** complete vs incomplete result card; only the Class Teacher
   gets `canPrint` (VP: view only); a subject teacher cannot delete (403); the Class Teacher's
   delete removes the student from all subjects and the subject teachers see a removal notice.
7. **Publish & lock:** Class Teacher publishes 9-A; adding students / saving marks in a
   locked class → 409; only the Class Teacher may publish (403); unpublish again.
   *Folder 1 also checks the two login screens:* Admin on Admin Login (200), Teacher/VP on Staff
   Login (200), Admin on Staff Login and Teacher on Admin Login (403, no token), and a wrong
   password on Admin Login (401, so the role of an account is never revealed).
   *Folder 2 also checks* that a Principal/VP cannot get subjects and that the same
   subject + class cannot be picked twice (400).
8. **Admin – classes & teachers:** list subjects; create a class with subject teachers (201);
   duplicate name / teacher already leading another class (409); missing section (400);
   teacher not allowed (403); change the Class Teacher and subject teachers (200); removing a
   subject that already has marks is refused (409) and nothing changes. Then the whole class is
   edited at once (`PUT /classes/{id}`: rename + add Physics, 200; name of another class 409;
   teacher 403) and the new teacher is edited (`PUT /users/{id}`: new name, Physics moves to them,
   Biology is added, 200); taking away subjects that have marks (409), a class that already has
   a Class Teacher (409), the Admin account (400) and a teacher editing users (403) are refused.
9. **Admin – subjects:** add a subject (201); the same name in CAPITALS (409); empty name or
   max marks 0 (400); rename + new max marks (200); rename to an existing subject (409); max
   below a mark already given (409); not found (404); teacher (403); delete a subject that is
   taught in classes (409); delete the unused new subject (200); back to 5 subjects.
10. **Admin – soft & hard delete** (names from the Assignment 2 Web API):
   *Teacher:* a new teacher is soft-deleted (`DELETE /users/SoftDeleteById?id=`, 200) and then
   disappears from `GET /users`, cannot log in (401) and its old token stops working (401);
   a teacher (403), the Admin's own account (400), a teacher who still leads a class (409) and an
   unknown id (404) are refused. `GET /users/GetDeleted` still finds the row, `PUT
   /users/RestoreById?id=` brings it back (login works again; restoring twice = 400).
   `DELETE /users/HardDeleteById?id=` is refused for a teacher with marks (409), the own account
   (400) and a teacher (403); the soft-deleted teacher is then removed for ever (200, then 404).
   *Class:* a new class with a subject and a student is soft-deleted: it leaves the overview and
   Sania's subject list, its tracker and result cards give 404, and its name cannot be reused
   (409). `GetDeleted` / `RestoreById` work like for users. `HardDeleteById` refuses 8-B (it has
   marks, 409) and removes the new class with its student and subject (200, then 404).
11. **Result Date & notifications** (own backend, no Firebase):
   *Result Date:* everyone can read it (no token = 401). A teacher or the Admin cannot set it
   (403), and a past date is refused (400). The VP sets it 7, 4 and 2 days ahead; the dates come
   from the server's `today`, so the run works on any day.
   *Automatic reminders:* after each move, Usman (pending Physics) gets exactly one
   `deadline_one_week`, `deadline_daily` and then urgent `deadline_urgent`. A second GET
   makes no duplicate, and the VP gets none.
   *Suppression:* a new teacher with one subject gets the urgent reminder, then submits ALL
   marks. The reminder is marked read, and moving the date to 5 days creates no new reminder.
   *Class Teacher reminder:* Sania nudges Usman for Physics 8-B (201), and again at once (429).
   Already-submitted English (409), her own Chemistry (400), another Class Teacher, a subject
   teacher, the VP and the Admin (403), and an unknown subject (404) are refused. Usman sees the
   reminder (from Teacher Sania, with the note, newest first) and reads it; reading someone
   else's gives 404. After that a new nudge is allowed (201), then read-all leaves 0 unread.
   *Clean up:* the marks are cleared and Biology 9-C goes back to Sania. The new teacher is
   hard-deleted (their notifications go too: `ON DELETE CASCADE`), and the Result Date is cleared.

The collection cleans up after itself (deletes the student it adds, unpublishes 9-A),
so it can be run again and again. Each run adds one new teacher account (`ali@school.com`,
`ali2@school.com`, …) and one new class (`Class 11 - T<random>` after its rename); the subject it
adds is deleted again. Folder 10's teacher and class are hard-deleted at the end; folder 11
re-submits English 8-B (folder 4's new student had un-submitted it) and clears the Result Date.


## Against Azure
Start the Azure MySQL server first (Portal → server → **Start**), then double-click
`run_tests_azure.cmd`. Afterwards put the cloud data back to the clean demo data:
`tools\.venv\Scripts\python -I tools\azure\import_to_azure.py --reset`.
