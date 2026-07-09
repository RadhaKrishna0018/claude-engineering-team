#!/usr/bin/env bash
# ⚡ Claude Engineering Team — one-liner bootstrap
#
# Usage (from the root of ANY target repository):
#   curl -fsSL https://raw.githubusercontent.com/<you>/claude-engineering-team/master/scripts/install.sh | bash
#
# Or with a custom source (fork / private mirror):
#   TEAM_SRC=https://raw.githubusercontent.com/<org>/<fork>/master bash install.sh
set -euo pipefail

TEAM_SRC="${TEAM_SRC:-https://raw.githubusercontent.com/<you>/claude-engineering-team/master}"
DIR=".claudecode"

echo "⚡ Installing Claude Engineering Team into $(pwd)"

[ -d .git ] || { echo "✗ Not a git repository root. cd to your repo root first."; exit 1; }

mkdir -p "$DIR/plans" "$DIR/handoffs"

# 1. Global skill — never clobber a locally customized copy without backup
if [ -f "$DIR/instructions.md" ]; then
  cp "$DIR/instructions.md" "$DIR/instructions.md.bak"
  echo "• Existing instructions.md backed up → instructions.md.bak"
fi
curl -fsSL "$TEAM_SRC/.claudecode/instructions.md" -o "$DIR/instructions.md"
echo "• Installed $DIR/instructions.md (7-role team skill)"

# 2. Metrics ledger — create only if absent (it is append-only local state)
if [ ! -f "$DIR/metrics.json" ]; then
  curl -fsSL "$TEAM_SRC/.claudecode/metrics.json" -o "$DIR/metrics.json"
  # stamp instance metadata
  repo_name="$(basename "$(git rev-parse --show-toplevel)")"
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  tmp="$(mktemp)"
  sed -e "s/\"repo\": \"\"/\"repo\": \"$repo_name\"/" \
      -e "s/\"started\": \"[^\"]*\"/\"started\": \"$now\"/" \
      "$DIR/metrics.json" > "$tmp" && mv "$tmp" "$DIR/metrics.json"
  echo "• Created $DIR/metrics.json ledger (repo=$repo_name)"
else
  echo "• Kept existing metrics.json ledger"
fi

# 3. Wire into CLAUDE.md so Claude Code loads the skill automatically
MARKER="<!-- claude-engineering-team -->"
if ! grep -qs "$MARKER" CLAUDE.md 2>/dev/null; then
  {
    echo ""
    echo "$MARKER"
    echo "## Engineering Team"
    echo "This repository is staffed by the Claude Engineering Team."
    echo "Read and obey \`.claudecode/instructions.md\` for all engineering tasks."
  } >> CLAUDE.md
  echo "• Linked skill from CLAUDE.md"
else
  echo "• CLAUDE.md already linked"
fi

# 4. Keep local team state out of accidental commits (plans/handoffs are ephemeral)
if ! grep -qs "^.claudecode/handoffs/" .gitignore 2>/dev/null; then
  printf ".claudecode/handoffs/\n.claudecode/metrics.json\n" >> .gitignore
  echo "• .gitignore updated (handoffs + private cost ledger)"
fi

echo ""
echo "✅ Done. Open Claude Code in this repo and state a goal — the CTO takes it from there."
echo "   Optional dashboard: $TEAM_SRC → dashboard/index.html (see docs/SETUP.md)"
