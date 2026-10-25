#!/usr/bin/env bash
# Removes what install.sh added: only symlinks that point into this repo, the
# ALPHA_HOME env var and the guard hook. Credentials files are left alone.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"

for link in "$CLAUDE_DIR"/skills/* "$CLAUDE_DIR"/agents/*; do
  [ -L "$link" ] || continue
  case "$(readlink "$link")" in
    "$ROOT"/*) rm "$link" && echo "removed $link" ;;
  esac
done

if [ -f "$SETTINGS" ]; then
  cp "$SETTINGS" "$SETTINGS.bak-alpha-$(date +%Y%m%d%H%M%S)"
  tmp="$(mktemp)"
  jq '
    (if .env then .env |= del(.ALPHA_HOME) else . end)
    | (if .hooks.PreToolUse then
         .hooks.PreToolUse |= [ .[] | select([.hooks[]?.args[]?] | any(endswith("guard-env.mjs")) | not) ]
       else . end)
  ' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  echo "cleaned $SETTINGS"
fi
rm -f "$HOME/.config/alpha/test-run.json"
