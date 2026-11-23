"""Small helper to drive a Flutter **web** build with Playwright (headless Edge).

Flutter draws on a <canvas>, so we turn on Flutter's accessibility tree
("semantics"), which adds real DOM nodes (inputs, buttons, text) that
Playwright can find and click. Screenshots still show the normal UI.
"""

import re
from pathlib import Path

from playwright.sync_api import Page, sync_playwright

PHONE = {"width": 390, "height": 844}


class FlutterApp:
    def __init__(self, page: Page, out_dir: Path):
        self.page = page
        self.out_dir = out_dir
        out_dir.mkdir(parents=True, exist_ok=True)

    # ---------- startup ----------
    def open(self, url: str):
        self.page.goto(url, wait_until="networkidle")
        self.page.wait_for_selector("flt-semantics-placeholder", state="attached", timeout=60000)
        self.page.wait_for_timeout(1000)
        self.page.locator("flt-semantics-placeholder").dispatch_event("click")
        self.page.wait_for_selector("flt-semantics-host flt-semantics", state="attached")
        self.page.wait_for_timeout(500)

    # ---------- waiting ----------
    def wait_text(self, text: str, timeout: int = 15000):
        """Wait until some visible text / label contains `text`."""
        self.page.wait_for_function(
            """t => {
                const h = document.querySelector('flt-semantics-host');
                if (!h) return false;
                if (h.textContent.includes(t)) return true;
                return [...h.querySelectorAll('[aria-label]')]
                    .some(e => (e.getAttribute('aria-label') || '').includes(t));
            }""",
            arg=text,
            timeout=timeout,
        )
        self.page.wait_for_timeout(450)  # let animations finish

    def wait_gone(self, text: str, timeout: int = 15000):
        self.page.wait_for_function(
            """t => {
                const h = document.querySelector('flt-semantics-host');
                return h && !h.textContent.includes(t);
            }""",
            arg=text,
            timeout=timeout,
        )
        self.page.wait_for_timeout(300)

    def pause(self, ms: int = 400):
        self.page.wait_for_timeout(ms)

    # ---------- finding things ----------
    def _tappables(self):
        return self.page.locator(
            "flt-semantics[flt-tappable], flt-semantics[role='button'], "
            "flt-semantics[role='checkbox'], flt-semantics[role='menuitem'], "
            "flt-semantics[role='option'], flt-semantics[role='tab'], "
            "flt-semantics[role='link'], flt-semantics[role='radio']"
        )

    def tap(self, text: str, index: int = 0, last: bool = False):
        """Tap a button / list tile whose text contains `text`."""
        loc = self._tappables().filter(has_text=text)
        if loc.count() == 0:
            # some widgets (e.g. dropdown menu items) keep their text in aria-label
            safe = text.replace('"', '\\"')
            loc = self._tappables().and_(self.page.locator(f'[aria-label*="{safe}"]'))
        target = loc.last if last else loc.nth(index)
        target.click()
        self.page.wait_for_timeout(350)

    def tap_label(self, label: str, index: int = 0):
        """Tap an icon button by its tooltip (aria-label), e.g. 'Back'."""
        # Flutter puts an icon button's tooltip as the button's own text
        exact = re.compile(rf"^\s*{re.escape(label)}\s*$")
        self.page.locator("flt-semantics[role='button']").filter(has_text=exact).nth(index).click()
        self.page.wait_for_timeout(350)

    def open_drawer(self):
        self.tap_label("Open navigation menu")
        self.pause(500)

    def back(self):
        self.tap_label("Back")
        self.pause(500)

    def type_into(self, label_start: str, text: str, index: int = 0):
        """Type into the text field whose label starts with `label_start`."""
        field = self.page.locator(f"input[aria-label^='{label_start}']").nth(index)
        self._replace_text(field, text)

    def type_into_nth_input(self, index: int, text: str):
        field = self.page.locator("flt-semantics-host input").nth(index)
        self._replace_text(field, text)

    def _replace_text(self, field, text: str):
        # Flutter sends key presses to its own hidden <input>, so we click the
        # field, delete what is there with Backspace, then type the new text.
        field.click()
        self.page.wait_for_timeout(150)
        self.page.keyboard.press("End")
        for _ in range(40):
            self.page.keyboard.press("Backspace")
        self.page.keyboard.type(text, delay=15)
        self.page.wait_for_timeout(150)

    def scroll(self, dy: int, x: int = 195, y: int = 450):
        self.page.mouse.move(x, y)
        self.page.mouse.wheel(0, dy)
        self.page.wait_for_timeout(600)

    def all_labels(self) -> list[str]:
        return self.page.evaluate(
            """() => {
                const h = document.querySelector('flt-semantics-host');
                const out = [];
                h.querySelectorAll('flt-semantics').forEach(e => {
                    const t = (e.getAttribute('aria-label') || '') + ' ' +
                        [...e.childNodes].filter(n => n.nodeType === 3 || n.tagName === 'SPAN')
                            .map(n => n.textContent).join(' ');
                    if (t.trim()) out.push(t.trim());
                });
                return out;
            }"""
        )

    def clipboard_text(self) -> str:
        return self.page.evaluate("() => navigator.clipboard.readText()")

    # ---------- screenshots ----------
    def shot(self, name: str):
        path = self.out_dir / name
        self.page.screenshot(path=str(path))
        print("saved", path.name)


def run(url: str, out_dir: Path, scenario):
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="msedge", headless=True)
        context = browser.new_context(
            viewport=PHONE,
            device_scale_factor=2,
            permissions=["clipboard-read", "clipboard-write"],
        )
        page = context.new_page()
        app = FlutterApp(page, out_dir)
        app.open(url)
        try:
            scenario(app)
        except Exception:
            page.screenshot(path=str(out_dir / "_error_state.png"))
            raise
        finally:
            browser.close()
