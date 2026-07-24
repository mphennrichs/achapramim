#!/bin/sh
# Fixture de teste: ecoa o stdin de volta, envolto num objeto {"ok": true, "echo": <stdin>}.
input=$(cat)
printf '{"ok": true, "echo": %s}' "$input"
