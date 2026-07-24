#!/bin/sh
# Fixture de teste pra Fetch(): devolve um JSON canned de listings, sem
# depender de Python/Playwright/browser real. Ignora o stdin (a URL
# recebida), sempre retorna o mesmo conjunto fixo.
cat > /dev/null
cat <<'EOF'
{
  "ok": true,
  "listings": [
    {"externalId": "111", "url": "https://olx.com.br/111", "title": "Frigobar novo", "imageUrl": "https://img/1.jpg", "priceText": "R$ 600"},
    {"externalId": "222", "url": "https://olx.com.br/222", "title": "Preco invalido", "imageUrl": "https://img/2.jpg", "priceText": "Preço a combinar"}
  ],
  "error": null
}
EOF
