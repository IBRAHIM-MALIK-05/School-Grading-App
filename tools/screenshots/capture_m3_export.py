"""Milestone 3 (part 1, local): export school_grading from XAMPP phpMyAdmin
as a clean SQL file for Azure MySQL, and screenshot the export settings.

    tools\\.venv\\Scripts\\python -I tools\\screenshots\\capture_m3_export.py

Output: database/03_school_grading_export_for_azure.sql
"""

import sys
from pathlib import Path

from playwright.sync_api import sync_playwright

sys.path.insert(0, str(Path(__file__).parent))
from text_image import render  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "screenshots"
EXPORT_FILE = ROOT / "database" / "03_school_grading_export_for_azure.sql"
PMA = "http://localhost/phpmyadmin/index.php"


def set_checkbox(page, element_id: str, checked: bool):
    box = page.locator(f"#{element_id}")
    if box.is_checked() != checked:
        box.click()


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="msedge", headless=True)
        page = browser.new_page(viewport={"width": 1366, "height": 768}, accept_downloads=True)
        page.goto(f"{PMA}?route=/database/export&db=school_grading", wait_until="networkidle")
        page.click("#radio_custom_export")
        page.wait_for_timeout(500)

        # Clean settings for a different server (Azure MySQL 8):
        set_checkbox(page, "checkbox_sql_create_database", False)  # database is created on Azure first
        set_checkbox(page, "checkbox_sql_drop_table", True)        # import can be run again safely
        set_checkbox(page, "checkbox_sql_disable_fk", True)        # load tables in any order
        set_checkbox(page, "checkbox_sql_use_transaction", True)   # all or nothing
        # Puts PRIMARY KEY + indexes INSIDE "CREATE TABLE" (instead of a later
        # ALTER TABLE). Azure MySQL can require every new table to have a
        # primary key straight away (sql_require_primary_key).
        set_checkbox(page, "checkbox_sql_if_not_exists", True)
        page.select_option("#select_sql_compatibility", "NONE")
        page.wait_for_timeout(300)

        page.evaluate("window.scrollTo(0, 0)")
        page.screenshot(path=str(OUT / "m3_01_phpmyadmin_export_custom.png"))
        print("saved m3_01_phpmyadmin_export_custom.png")

        page.locator("#checkbox_sql_drop_table").scroll_into_view_if_needed()
        page.evaluate("window.scrollBy(0, -250)")
        page.wait_for_timeout(300)
        page.screenshot(path=str(OUT / "m3_02_phpmyadmin_export_options.png"))
        print("saved m3_02_phpmyadmin_export_options.png")

        with page.expect_download() as download_info:
            page.click("#buttonGo")
        download_info.value.save_as(str(EXPORT_FILE))
        print("exported", EXPORT_FILE.name, EXPORT_FILE.stat().st_size, "bytes")
        browser.close()

    # A picture of the start of the exported file
    lines = EXPORT_FILE.read_text(encoding="utf-8").splitlines()
    start = next(i for i, l in enumerate(lines) if l.startswith("CREATE TABLE") and "`classes`" in l)
    preview = lines[:22] + ["...", ""] + lines[start:start + 14] + ["..."]
    render(preview, OUT / "m3_03_export_file_preview.png",
           title=EXPORT_FILE.name, font_size=15)


if __name__ == "__main__":
    main()
