"""Extrai título + texto visível de uma página de anúncio via Playwright.
Chamado como subprocesso pelo backend Go (link-preview). Mesmo contrato
stdin/stdout de olx_search.py — ver esse arquivo para detalhes."""
import json
import sys

from playwright.sync_api import sync_playwright

from _common import launch_context


def run(url: str) -> dict:
    with sync_playwright() as p:
        browser, context = launch_context(p)
        try:
            page = context.new_page()
            page.goto(url, wait_until="load", timeout=30000)
            title = page.title()
            text = page.locator("body").inner_text()
            return {"ok": True, "title": title, "text": text, "error": None}
        finally:
            browser.close()


def main() -> None:
    try:
        req = json.loads(sys.stdin.read())
        result = run(req["url"])
    except Exception as e:
        result = {"ok": False, "title": "", "text": "", "error": str(e)}
    print(json.dumps(result))


if __name__ == "__main__":
    main()
