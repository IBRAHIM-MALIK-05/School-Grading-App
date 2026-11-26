"""Screenshots of the Notification System (Result Date + Notification Bell, no Firebase).

  1. Principal / VP: Result Date card, calendar, date set to 2 days from today (URGENT range).
  2. Class Teacher Sania: Result Date banner, My Class -> "Notify" on the pending Physics subject,
     note + confirmation, "Reminder sent to Teacher Usman for Physics."
  3. Teacher Usman: bell badge + in-app message, Notifications screen with the Class Teacher
     reminder and the URGENT 2-day alert, mark as read, enable browser alerts, mark all read.
  4. The rows in MySQL (school_settings + notifications) and the new endpoints in Swagger.
New files only: m7e_*.png (existing screenshots are never overwritten).

Needs: the API on http://localhost:5080 (local XAMPP, clean demo data) and a web build pointed
at it, served on http://127.0.0.1:8766/
    tools\\.venv\\Scripts\\python -I tools\\screenshots\\capture_m7e_notifications.py
Afterwards reset the local data (drop school_grading, 01_create_database.sql, Update-Database).
"""

import datetime as dt
import json
import subprocess
import sys
import urllib.request
from pathlib import Path

from playwright.sync_api import sync_playwright

sys.path.insert(0, str(Path(__file__).parent))
from flutter_driver import FlutterApp, run  # noqa: E402
from text_image import render  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "screenshots"
APP_URL = "http://127.0.0.1:8766/"
API = "http://localhost:5080/api"
SWAGGER = "http://localhost:5080/swagger/index.html"
MYSQL = r"d:\xampp\mysql\bin\mysql.exe"


def check_name(name: str):
    if not name.startswith("m7e_") or (OUT / name).exists():
        raise RuntimeError(f"refusing to overwrite / misname {name}")


class SafeApp(FlutterApp):
    """Refuses to overwrite any screenshot that already exists."""

    def shot(self, name: str):
        check_name(name)
        self.page.mouse.move(200, 30)  # park the mouse so no hover tooltip shows
        self.pause(600)
        super().shot(name)


def api(method, path, body=None, token=None):
    req = urllib.request.Request(API + path, method=method,
                                 data=None if body is None else json.dumps(body).encode())
    req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", "Bearer " + token)
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read() or b"null")


def login(app: FlutterApp, login_id: str, wait_for: str):
    app.wait_text("School Grading System")
    app.type_into("Login ID", login_id)
    app.type_into("Password", "123")
    app.tap("Login", last=False)
    app.wait_text(wait_for, timeout=60000)


# ---------------------------------------------------------------- 1) Principal / VP
def vp_scenario(app: FlutterApp, result_day: dt.date):
    app.__class__ = SafeApp
    login(app, "vp@school.com", "Not set yet")
    app.shot("m7e_01_vp_result_date_not_set.png")

    app.tap("Set / Change Result Date")
    app.wait_text("Pick the Result Date")
    app.shot("m7e_02_vp_calendar.png")

    # type the date (calendar "input" mode) = 2 days from today -> URGENT range for teachers
    app.tap_label("Switch to input")
    app.pause(500)
    app.type_into("Enter Date", result_day.strftime("%m/%d/%Y"))
    app.tap("Set date")
    app.wait_text("Result Date set to")
    app.wait_text("2 days left")
    app.shot("m7e_03_vp_result_date_set.png")


# ---------------------------------------------------------------- 2) Class Teacher Sania
def class_teacher_scenario(app: FlutterApp):
    app.__class__ = SafeApp
    login(app, "sania@school.com", "Result Date:")
    app.pause(1500)  # in-app message for her own urgent reminder (she has pending subjects too)
    app.shot("m7e_04_teacher_result_date_banner.png")
    app.tap_label("Close")  # close the in-app message
    app.pause(600)

    app.tap("Open my class")
    app.wait_text("1. Subjects", timeout=30000)
    app.shot("m7e_05_my_class_notify_button.png")

    app.tap("Notify")
    app.wait_text("Notify Teacher Usman?")
    # a 2-line text field is a <textarea> in Flutter web (type_into only looks at <input>)
    app._replace_text(app.page.locator("textarea[aria-label^='Short note']").first,
                      "Please submit Physics by Friday.")
    app.page.keyboard.press("Tab")
    app.shot("m7e_06_notify_dialog.png")

    app.tap("Send reminder")
    app.wait_text("Reminder sent to Teacher Usman for Physics.")
    app.shot("m7e_07_reminder_sent.png")


# ---------------------------------------------------------------- 3) Teacher Usman
def subject_teacher_scenario(app: FlutterApp):
    app.__class__ = SafeApp
    login(app, "usman@school.com", "You have 2 new notifications.")
    app.shot("m7e_08_teacher_bell_badge.png")

    # Headless Edge answers "denied" for notifications by default. Allow them now (after login,
    # so nothing is switched on by itself): the screen then offers "Enable Desktop/Browser Alerts".
    app.page.context.grant_permissions(["notifications"], origin=APP_URL.rstrip("/"))

    app.tap("View")  # the in-app message's button opens the Notifications screen
    app.wait_text("Unread (2)")
    app.shot("m7e_09_notifications_screen.png")

    app.tap("Marks Reminder")
    app.wait_text("Unread (1)")
    app.shot("m7e_10_reminder_marked_read.png")

    # "Enable Desktop/Browser Alerts": a real click asks the browser, which allows it
    app.tap("Enable Desktop/Browser Alerts")
    app.wait_text("Pop-up alerts are on")
    app.shot("m7e_11_browser_alerts_enabled.png")
    app.wait_gone("Pop-up alerts are on", timeout=15000)

    app.tap("Mark all read")
    app.wait_text("All notifications marked as read.")
    app.shot("m7e_12_all_read.png")


# ---------------------------------------------------------------- 4) MySQL + Swagger
def database_shot():
    queries = ["SELECT Id, ResultDate, UpdatedByUserId FROM school_settings;",
               "SELECT Id, RecipientUserId AS `To`, SenderUserId AS `From`, Type, IsUrgent, IsRead, "
               "NotificationDate FROM notifications;"]
    lines = []
    for q in queries:
        out = subprocess.run([MYSQL, "-u", "root", "-t", "-e", q, "school_grading"],
                             capture_output=True, text=True, check=True).stdout
        lines += [f"MariaDB [school_grading]> {q}"] + out.rstrip().splitlines() + [""]
    lines.append("-- From = NULL : automatic Result Date reminder (no cron: made when the teacher opens the app)")
    lines.append("-- From = 3    : Class Teacher Sania's reminder to Usman (6)")
    name = "m7e_13_database_notifications.png"
    check_name(name)
    render(lines, OUT / name, title="XAMPP MySQL - Result Date + notifications")
    print("saved", name)


def save_element(locator, name):
    check_name(name)
    locator.scroll_into_view_if_needed()
    locator.screenshot(path=str(OUT / name))
    print("saved", name)


def swagger_shots():
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="msedge", headless=True)
        page = browser.new_page(viewport={"width": 1366, "height": 900})
        page.goto(SWAGGER, wait_until="networkidle")
        page.wait_for_selector(".opblock", timeout=20000)
        for tag, name in [("Notifications", "m7e_14_swagger_notifications_endpoints.png"),
                          ("Settings", "m7e_15_swagger_settings_endpoints.png")]:
            section = page.locator(".opblock-tag-section").filter(has=page.locator(f"#operations-tag-{tag}"))
            save_element(section, name)
        browser.close()


def main():
    vp = api("POST", "/auth/login", {"loginId": "vp@school.com", "password": "123"})["token"]
    today = dt.date.fromisoformat(api("GET", "/settings/result-date", token=vp)["today"])

    run(APP_URL, OUT, lambda app: vp_scenario(app, today + dt.timedelta(days=2)))
    run(APP_URL, OUT, class_teacher_scenario)
    run(APP_URL, OUT, subject_teacher_scenario)
    database_shot()
    swagger_shots()


if __name__ == "__main__":
    main()
