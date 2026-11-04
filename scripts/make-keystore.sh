#!/usr/bin/env bash
set -euo pipefail

ALIAS="${1:-pc5}"
OUT="${2:-pc5.keystore}"

keytool -genkeypair \
  -v \
  -keystore "$OUT" \
  -alias "$ALIAS" \
  -keyalg RSA \
  -keysize 4096 \
  -validity 10000 \
  -dname "CN=PC5 Android, OU=PC5, O=PC5, L=Tehran, C=IR"

echo
echo "keystore: $OUT"
echo "alias:    $ALIAS"
echo
echo "Set these repo secrets:"
echo "  KEYSTORE_B64      -> $(base64 -w0 "$OUT" | head -c 40)…"
echo "  STORE_PASSWORD    -> the store password you typed"
echo "  KEY_ALIAS         -> $ALIAS"
echo "  KEY_PASSWORD      -> the key password you typed"
