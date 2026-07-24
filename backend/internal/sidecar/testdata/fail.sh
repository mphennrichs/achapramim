#!/bin/sh
# Fixture de teste: falha com stderr preenchido e exit code != 0.
echo "something went wrong" >&2
exit 1
