#!/usr/bin/env bash
# Build this checkout and install it as the global `prime-agent` command.
#
# Usage:
#   ./scripts/install-global.sh [--skip-deps] [--pack-only]

set -euo pipefail

cd "$(dirname "$0")/.."

SKIP_DEPS=false
PACK_ONLY=false
OUTPUT_DIR="packages/coding-agent/release/global-install"

while [[ $# -gt 0 ]]; do
	case "$1" in
		--skip-deps)
			SKIP_DEPS=true
			shift
			;;
		--pack-only)
			PACK_ONLY=true
			shift
			;;
		-h|--help)
			printf 'Usage: %s [--skip-deps] [--pack-only]\n' "$0"
			exit 0
			;;
		*)
			printf 'error: unknown option: %s\n' "$1" >&2
			exit 1
			;;
	esac
done

for command_name in node npm; do
	if ! command -v "$command_name" >/dev/null 2>&1; then
		printf 'error: required command not found: %s\n' "$command_name" >&2
		exit 1
	fi
done

if [[ "$SKIP_DEPS" == "false" ]]; then
	printf '==> Installing workspace dependencies\n'
	npm ci
else
	printf '==> Skipping workspace dependency installation\n'
fi

printf '==> Building Prime Agent\n'
npm --prefix packages/tui run build
npm exec -- tsgo -p packages/ai/tsconfig.build.json
npm --prefix packages/agent run build
npm --prefix packages/coding-agent run build

VERSION=$(node -p "require('./packages/coding-agent/package.json').version")
ABSOLUTE_OUTPUT_DIR="$PWD/$OUTPUT_DIR"
DEPENDENCY_ROOT="$ABSOLUTE_OUTPUT_DIR/dependencies"
DEPENDENCY_BASE_URL=$(node --input-type=module -e \
	'import { pathToFileURL } from "node:url"; console.log(pathToFileURL(process.argv[1]).href)' \
	"$DEPENDENCY_ROOT")

printf '==> Packing Prime Agent %s\n' "$VERSION"
node scripts/pack-prime-agent-release.mjs \
	--base-url "$DEPENDENCY_BASE_URL" \
	--version "$VERSION" \
	--out-dir "$OUTPUT_DIR"

DEPENDENCY_RELEASE_DIR="$DEPENDENCY_ROOT/releases/v$VERSION"
mkdir -p "$DEPENDENCY_RELEASE_DIR"
cp "$ABSOLUTE_OUTPUT_DIR/artifacts/prime-agent-ai-$VERSION.tgz" "$DEPENDENCY_RELEASE_DIR/"
cp "$ABSOLUTE_OUTPUT_DIR/artifacts/prime-agent-core-$VERSION.tgz" "$DEPENDENCY_RELEASE_DIR/"
cp "$ABSOLUTE_OUTPUT_DIR/artifacts/prime-agent-tui-$VERSION.tgz" "$DEPENDENCY_RELEASE_DIR/"

TARBALL="$ABSOLUTE_OUTPUT_DIR/artifacts/prime-agent-$VERSION.tgz"
if [[ ! -f "$TARBALL" ]]; then
	printf 'error: package was not created: %s\n' "$TARBALL" >&2
	exit 1
fi

if [[ "$PACK_ONLY" == "true" ]]; then
	printf '==> Package ready: %s\n' "$TARBALL"
	exit 0
fi

printf '==> Installing global package\n'
npm install --global "$TARBALL"

INSTALLED_VERSION=$(prime-agent --version)
if [[ "$INSTALLED_VERSION" != "$VERSION" ]]; then
	printf 'error: installed version is %s; expected %s\n' "$INSTALLED_VERSION" "$VERSION" >&2
	exit 1
fi

printf '==> Installed %s (%s)\n' "$(command -v prime-agent)" "$INSTALLED_VERSION"
printf 'Restart all running Prime Agent sessions before testing this build.\n'
