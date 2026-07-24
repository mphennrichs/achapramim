"""Configuração de browser compartilhada pelos scripts do sidecar — mesma
combinação de user-agent/viewport/locale validada manualmente como capaz de
passar pela detecção anti-bot da Cloudflare no OLX (ver ADR sobre a migração
de chromedp para este sidecar)."""

USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
)


def launch_context(playwright):
    browser = playwright.chromium.launch(headless=True)
    context = browser.new_context(
        user_agent=USER_AGENT,
        viewport={"width": 1366, "height": 768},
        locale="pt-BR",
    )
    return browser, context
