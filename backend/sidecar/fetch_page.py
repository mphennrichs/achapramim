"""Extrai título + texto visível de uma página de anúncio via Playwright.
Chamado como subprocesso pelo backend Go (link-preview). Mesmo contrato
stdin/stdout de olx_search.py — ver esse arquivo para detalhes."""
import ipaddress
import json
import socket
import sys
from urllib.parse import urlsplit

from playwright.sync_api import sync_playwright

from _common import launch_context


def _is_public_host(host: str) -> bool:
    """True só se o host resolve exclusivamente para IPs públicos.
    O backend Go já valida a URL inicial (linkpreview.ValidatePublicURL); aqui
    a checagem se repete em CADA requisição do browser, porque um anúncio pode
    redirecionar ou carregar sub-recursos de http://dockerproxy:2375 etc."""
    try:
        infos = socket.getaddrinfo(host, None)
    except OSError:
        return False
    if not infos:
        return False
    for info in infos:
        ip = ipaddress.ip_address(info[4][0])
        if getattr(ip, "ipv4_mapped", None):
            ip = ip.ipv4_mapped
        if not ip.is_global:  # cobre privado, loopback, link-local, CGNAT (Tailscale)
            return False
    return True


def _guard(route) -> None:
    parts = urlsplit(route.request.url)
    if parts.scheme in ("data", "blob"):
        route.continue_()
        return
    if parts.scheme not in ("http", "https") or not parts.hostname or not _is_public_host(parts.hostname):
        route.abort("blockedbyclient")
        return
    route.continue_()


def run(url: str) -> dict:
    with sync_playwright() as p:
        browser, context = launch_context(p)
        try:
            context.route("**/*", _guard)
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
