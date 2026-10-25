#!/usr/bin/env bash
# Installs the workflow for the current user:
#   - symlinks skills/* into ~/.claude/skills (invoked as /work, /plan, …)
#   - symlinks agents/*.md into ~/.claude/agents
#   - sets ALPHA_HOME and the /automation-test navigation guard hook in ~/.claude/settings.json
# Safe to re-run. Undo with ./uninstall.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
GUARD="$ROOT/hooks/guard-env.mjs"

command -v jq >/dev/null || { echo "jq is required (brew install jq)"; exit 1; }
command -v node >/dev/null || { echo "node is required"; exit 1; }
mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/agents"

link() { # link <source> <target>
  local src="$1" dst="$2"
  if [ -L "$dst" ]; then
    if [ "$(readlink "$dst")" = "$src" ]; then echo "ok      $dst"; return; fi
    echo "SKIP    $dst is a symlink to $(readlink "$dst"); remove it first"; return
  fi
  if [ -e "$dst" ]; then echo "SKIP    $dst already exists (not ours); remove or rename it first"; return; fi
  ln -s "$src" "$dst" && echo "linked  $dst -> $src"
}

for dir in "$ROOT"/skills/*/; do
  name="$(basename "$dir")"
  link "$ROOT/skills/$name" "$CLAUDE_DIR/skills/$name"
done
for file in "$ROOT"/agents/*.md; do
  link "$file" "$CLAUDE_DIR/agents/$(basename "$file")"
done

[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
cp "$SETTINGS" "$SETTINGS.bak-alpha-$(date +%Y%m%d%H%M%S)"
tmp="$(mktemp)"
jq --arg home "$ROOT" --arg guard "$GUARD" '
  .env = ((.env // {}) + { ALPHA_HOME: $home })
  | .hooks = (.hooks // {})
  | .hooks.PreToolUse = (
      [ (.hooks.PreToolUse // [])[]
        | select([.hooks[]?.args[]?] | any(endswith("guard-env.mjs")) | not) ]
      + [ { matcher: "mcp__claude-in-chrome__navigate",
            hooks: [ { type: "command", command: "node", args: [$guard] } ] } ]
    )
' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
echo "settings ALPHA_HOME=$ROOT, guard hook -> $GUARD (backup next to $SETTINGS)"

echo
echo "Done. Restart Claude Code, then try: /work <project> <request>"
echo "Test accounts: cp $ROOT/skills/automation-test/credentials.example.yaml ~/.config/alpha/credentials/<project>.yaml && chmod 600 it"
