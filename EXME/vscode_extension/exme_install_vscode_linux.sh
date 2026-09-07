#!/usr/bin/env sh
set -eu
DEST="$HOME/.vscode/extensions/exme-manual-language-2.0.0"
rm -rf "$DEST"
mkdir -p "$DEST"
cp -R "$(dirname "$0")"/. "$DEST"/
echo "EXME Manual VS Code extension installed. Restart VS Code."
