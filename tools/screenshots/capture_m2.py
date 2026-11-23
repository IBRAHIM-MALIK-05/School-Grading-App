"""Milestone 2 screenshots: creates the `school_grading` database through the
phpMyAdmin web UI (XAMPP) and captures each step into docs/screenshots/.

Usage (XAMPP Apache + MySQL running):
    tools\\.venv\\Scripts\\python -I tools\\screenshots\\capture_m2.py
"""

from pathlib import Path

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "screenshots"
PMA = "http://localhost/phpmyadmin/index.php"
DB = "school_grading"
COLLATION = "utf8mb4_general_ci"
DESKTOP = {"width": 1366, "height": 768}


def shot(page, name):
    page.wait_for_timeout(600)
    page.screenshot(path=str(OUT / name))
    print("saved", name)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="msedge", headless=True)
        page = browser.new_page(viewport=DESKTOP)

        # 1) phpMyAdmin home (server info: MariaDB, charset)
        page.goto(PMA, wait_until="networkidle")
        shot(page, "m2_02_phpmyadmin_home.png")

        # 2) Databases tab -> fill the "Create database" form
        page.goto(f"{PMA}?route=/server/databases", wait_until="networkidle")
        if page.locator(f"a:text-is('{DB}')").count() > 0:
            raise SystemExit(f"Database '{DB}' already exists - nothing to create.")
        page.fill("input[name='new_db']", DB)
        page.select_option("select[name='db_collation']", COLLATION)
        shot(page, "m2_03_create_database_form.png")

        # 3) Press "Create" -> phpMyAdmin opens the new, empty database
        page.click("#buttonGo")
        page.wait_for_selector("text=No tables found in database", timeout=15000)
        shot(page, "m2_04_database_created.png")

        # 4) Databases list shows the collation of every database
        page.goto(f"{PMA}?route=/server/databases", wait_until="networkidle")
        page.locator(f"tr:has(a:text-is('{DB}'))").first.scroll_into_view_if_needed()
        shot(page, "m2_05_database_list_collation.png")

        # 5) Operations tab of the database shows its collation setting
        page.goto(f"{PMA}?route=/database/operations&db={DB}", wait_until="networkidle")
        page.locator("text=Collation").first.scroll_into_view_if_needed()
        shot(page, "m2_06_database_operations_collation.png")

        browser.close()


if __name__ == "__main__":
    main()
