#!/bin/sh
# Fixture de teste: simula falha de scraping esperada (ok=false), não erro
# de infraestrutura.
cat > /dev/null
echo '{"ok": false, "listings": [], "error": "cloudflare challenge"}'
