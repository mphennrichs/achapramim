"""Busca anúncios do OLX via Playwright. Chamado como subprocesso pelo
backend Go (ver backend/internal/sidecar). Contrato: lê um JSON de {"url"}
no stdin, sempre imprime exatamente um JSON no stdout e sai com código 0 —
mesmo em falha esperada (ok=false + error preenchido). Só uma falha
realmente inesperada (Playwright não conseguiu nem iniciar) sairia com
código != 0, deixando o lado Go tratar isso como erro de infraestrutura.
"""
import json
import sys

from playwright.sync_api import sync_playwright

from _common import launch_context

EXTRACTION_SCRIPT = """
() => {
  const cards = Array.from(document.querySelectorAll('section.olx-adcard'));
  return cards.map((card) => {
    const link = card.querySelector('a[data-testid="adcard-link"]');
    const titleEl = link ? link.querySelector('.olx-adcard__title') : null;
    const priceEl = card.querySelector('.olx-adcard__price');
    const img = card.querySelector('img');
    const href = link ? link.href : '';
    const idMatch = href.match(/-(\\d+)$/);
    return {
      externalId: idMatch ? idMatch[1] : '',
      url: href,
      title: titleEl ? titleEl.textContent.trim() : '',
      imageUrl: img ? img.src : '',
      priceText: priceEl ? priceEl.textContent.trim() : '',
    };
  }).filter((item) => item.externalId && item.url);
}
"""


def run(url: str) -> dict:
    with sync_playwright() as p:
        browser, context = launch_context(p)
        try:
            page = context.new_page()
            page.goto(url, wait_until="domcontentloaded", timeout=30000)
            try:
                page.wait_for_selector("section.olx-adcard", timeout=10000)
            except Exception:
                # Página carregou mas sem nenhum card — pode ser busca sem
                # resultado, não é necessariamente um erro.
                pass
            listings = page.evaluate(EXTRACTION_SCRIPT)
            return {"ok": True, "listings": listings, "error": None}
        finally:
            browser.close()


def main() -> None:
    try:
        req = json.loads(sys.stdin.read())
        result = run(req["url"])
    except Exception as e:
        result = {"ok": False, "listings": [], "error": str(e)}
    print(json.dumps(result))


if __name__ == "__main__":
    main()
