#!/usr/bin/env bash
set -euo pipefail

VERSION="0.1.0"
SOURCE_DIR="${PROVIDER_SOURCE_DIR:-../terraform-provider-bland}"

if ! command -v go >/dev/null 2>&1; then
  echo "ERROR: Go is required." >&2
  exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "ERROR: Provider repository not found at $SOURCE_DIR" >&2
  echo "Clone https://github.com/majestyz3/terraform-provider-bland next to this repo, or set PROVIDER_SOURCE_DIR." >&2
  exit 1
fi

OS="$(go env GOOS)"
ARCH="$(go env GOARCH)"
TARGET="$HOME/.terraform.d/plugins/registry.terraform.io/majestyz3/bland/$VERSION/${OS}_${ARCH}"
BINARY="$TARGET/terraform-provider-bland_v$VERSION"

mkdir -p "$TARGET"

echo "Building Bland provider $VERSION for ${OS}/${ARCH}..."
(
  cd "$SOURCE_DIR"
  go test ./...
  go vet ./...
  go build -ldflags "-X main.version=$VERSION" -o "$BINARY" .
)

chmod +x "$BINARY"
echo "Installed: $BINARY"
echo "Provider tests, vet, and build completed successfully."
