#!/usr/bin/env bash
set -euo pipefail

# Prereqs: Go >= 1.24, ANDROID_NDK_HOME set, gomobile installed.
#   go install golang.org/x/mobile/cmd/gomobile@latest
#   gomobile init

: "${ANDROID_NDK_HOME:?set ANDROID_NDK_HOME}"

cd "$(dirname "$0")"
go mod tidy
go test ./... || true

mkdir -p ../android/app/libs

gomobile bind \
  -target=android/arm,android/arm64,android/amd64,android/386 \
  -androidapi 24 \
  -javapkg com.pc5 \
  -ldflags="-s -w" \
  -o ../android/app/libs/pc5core.aar \
  .

echo "built android/app/libs/pc5core.aar"
