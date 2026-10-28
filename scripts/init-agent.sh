#!/usr/bin/env bash
# Creates agent.conf, the brain (from templates) and CLAUDE.md for a new agent.
# Usage: scripts/init-agent.sh "AgentName" "YourName" [discord|telegram|both]
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
AGENT_NAME="${1:?Usage: init-agent.sh \"AgentName\" \"YourName\"}"
USER_NAME="${2:?Usage: init-agent.sh \"AgentName\" \"YourName\"}"
SESSION="$(echo "$AGENT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')"
TODAY="$(date +%F)"
BRAIN="$REPO/brain"
case "${3:-discord}" in
  discord)  CHANNELS="discord";          CHAT_APPS="Discord" ;;
  telegram) CHANNELS="telegram";         CHAT_APPS="Telegram" ;;
  both)     CHANNELS="discord telegram"; CHAT_APPS="Discord and Telegram" ;;
  *) echo "Third argument must be discord, telegram or both." >&2; exit 1 ;;
esac

if [ -e "$BRAIN" ]; then
  echo "A brain already exists at $BRAIN — refusing to overwrite it." >&2
  exit 1
fi

cat > "$REPO/agent.conf" <<EOF
AGENT_NAME="$AGENT_NAME"
USER_NAME="$USER_NAME"
SESSION="$SESSION"
CREATED="$TODAY"
CHANNELS="$CHANNELS"
CHAT_APPS="$CHAT_APPS"
EOF

python3 -I - "$REPO/templates" "$REPO" "$AGENT_NAME" "$USER_NAME" "$TODAY" "$CHAT_APPS" <<'PY'
import os, re, sys
templates, repo, agent, user, today, chat_apps = sys.argv[1:7]
subs = {"{AgentName}": agent, "{UserName}": user, "{Date}": today,
        "{BrainPath}": "~/agent/brain", "{ChatApps}": chat_apps}
def fill(s):
    for k, v in subs.items():
        s = s.replace(k, v)
    return s
with open(os.path.join(templates, "brain.md")) as fh:
    parts = re.split(r"^===== FILE: (.+?) =====\n", fh.read(), flags=re.M)
count = 0
for rel, body in zip(parts[1::2], parts[2::2]):
    dest = os.path.join(repo, "brain", fill(rel))
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    with open(dest, "w") as fh:
        fh.write(fill(body).rstrip("\n") + "\n")
    count += 1
os.makedirs(os.path.join(repo, "brain", "Inbox"), exist_ok=True)
open(os.path.join(repo, "brain", "Inbox", ".keep"), "w").close()
with open(os.path.join(templates, "CLAUDE.md")) as fh:
    claude_md = fill(fh.read())
with open(os.path.join(repo, "CLAUDE.md"), "w") as fh:
    fh.write(claude_md)
print(f"Created {count} brain files and CLAUDE.md")
PY

# Claude Code reads ~/.claude/CLAUDE.md on every launch; point it at the repo copy
mkdir -p "$HOME/.claude"
if [ -e "$HOME/.claude/CLAUDE.md" ] && [ ! -L "$HOME/.claude/CLAUDE.md" ]; then
  mv "$HOME/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md.bak.$(date +%s)"
fi
ln -sfn "$REPO/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

echo "Agent '$AGENT_NAME' initialised for $USER_NAME ($CHAT_APPS). tmux session name: $SESSION"
