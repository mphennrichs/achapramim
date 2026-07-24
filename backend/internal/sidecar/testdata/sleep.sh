#!/bin/sh
# Fixture de teste: dorme mais que qualquer timeout de teste, pra validar
# que o cancelamento de contexto mata o processo.
sleep 30
echo '{"ok": true}'
