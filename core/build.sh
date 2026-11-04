#!/usr/bin/env bash
set -euo pipefail

# Prereqs: Go >= 1.24, ANDROID_NDK_HOME set, gomobile installed.
#   go install golang.org/x/mobile/cmd/gomobile@latest
#   gomobile init

: "${ANDROID_NDK_HOME:?set ANDROID_NDK_HOME}"

cd "$(dirname "$0")"

# The fork has no tags, so pin a pseudo-version. CI supplies it via CORE_VERSION;
# local runs resolve it themselves.
VERSION="${CORE_VERSION:-}"
if [ -z "$VERSION" ]; then
  VERSION=$(go list -m -f '{{.Version}}' github.com/Happ-proxy/Xray-core@main)
fi
if [ -z "$VERSION" ]; then
  echo "error: could not resolve Happ-proxy/Xray-core" >&2
  exit 1
fi
echo "pinning xray-core -> $VERSION"

go mod edit -replace "github.com/xtls/xray-core=github.com/Happ-proxy/Xray-core@${VERSION}"
go mod tidy

# Fail early with a readable message instead of a gomobile stack trace.
if ! go build ./...; then
  echo "error: core does not compile against $VERSION" >&2
  exit 1
fi

mkdir -p ../android/app/libs

gomobile bind \
  -target=android/arm,android/arm64,android/amd64,android/386 \
  -androidapi 24 \
  -javapkg com.pc5 \
  -ldflags="-s -w" \
  -o ../android/app/libs/pc5core.aar \
  .

echo "built android/app/libs/pc5core.aar"
