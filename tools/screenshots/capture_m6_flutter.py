"""Milestone 6 screenshots: the Flutter app talking to the LIVE API on Azure.

Needs the web build (with apiBaseUrl = the Azure URL) served on port 8765:
    python -m http.server 8765 -d mobile\\build\\web
    tools\\.venv\\Scripts\\python -I tools\\screenshots\\capture_m6_flutter.py

Every HTTP call the app makes is recorded and saved as a "network log" picture,
which proves the data comes from https://school-grading-api-bcgi.azurewebsites.net
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from flutter_driver import FlutterApp, run  # noqa: E402
from text_image import render  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "screenshots"
URL = "http://127.0.0.1:8765/"
CALLS = []


def record(response):
    if "azurewebsites.net" in response.url and response.request.method != "OPTIONS":
        CALLS.append(f"{response.request.method:<6} {response.status}  {response.url}")


def login(app: FlutterApp, login_id: str, password: str, expect: str):
    app.type_into("Login ID", login_id)
    app.type_into("Password", password)
    app.tap("Login", last=True)
    app.wait_text(expect, timeout=90000)  # first call may wake up the free F1 server


def logout(app: FlutterApp):
    app.open_drawer()
    app.tap("Logout")
    app.wait_text("School Grading System")


def scenario(app: FlutterApp):
    app.page.on("response", record)
    app.wait_text("School Grading System")

    login(app, "admin@school.com", "123", "Welcome School Admin")
    app.wait_text("usman@school.com")
    app.shot("m6_10_flutter_azure_admin_users.png")
    logout(app)

    login(app, "sania@school.com", "123", "Welcome Teacher Sania")
    app.shot("m6_11_flutter_azure_teacher_dashboard.png")
    app.open_drawer()
    app.tap("My Subjects")
    app.pause(500)
    app.tap("Class 8 - B")  # Chemistry 8-B
    app.wait_text("Max marks: 60")
    for i, v in [(1, "40"), (2, "35"), (3, "52"), (4, "44")]:
        app.type_into_nth_input(i, v)
    app.shot("m6_12_flutter_azure_marks_entry.png")
    app.tap("Submit", last=True)
    app.wait_text("Submit marks?")
    app.tap("Submit", last=True)
    app.wait_text("Welcome Teacher Sania", timeout=60000)
    app.wait_gone("Marks submitted!", timeout=10000)
    app.tap("Open my class")
    app.wait_text("Subject submissions")
    app.shot("m6_13_flutter_azure_class_tracker.png")
    app.back()
    logout(app)

    login(app, "vp@school.com", "123", "Class Grading Status")
    app.shot("m6_14_flutter_azure_vp_dashboard.png")

    lines = ["# Every request the Flutter app sent during this run (recorded in the browser)", ""]
    lines += CALLS
    render(lines, OUT / "m6_15_flutter_azure_network_log.png",
           title="Flutter app -> Azure App Service (HTTPS)", font_size=14)
    print("saved m6_15_flutter_azure_network_log.png")


if __name__ == "__main__":
    run(URL, OUT, scenario)
