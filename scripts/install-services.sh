#!/usr/bin/env bash
# Installs the systemd user services:
#   agent.service        – runs the agent in tmux, starts on boot, restarts if it dies
#   agent-backup.timer   – commits and pushes the brain to your private git repo hourly
# Usage: scripts/install-services.sh [--no-start]
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "$REPO/agent.conf"
CHANNEL_ARGS=""
for c in ${CHANNELS:-discord}; do
  CHANNEL_ARGS="$CHANNEL_ARGS plugin:$c@claude-plugins-official"
done
CHANNEL_ARGS="${CHANNEL_ARGS# }"
UNIT_DIR="$HOME/.config/systemd/user"
mkdir -p "$UNIT_DIR"

for f in agent.service agent-backup.service agent-backup.timer; do
  sed -e "s|@SESSION@|$SESSION|g" \
      -e "s|@AGENT_NAME@|$AGENT_NAME|g" \
      -e "s|@REPO@|$REPO|g" \
      -e "s|@CHANNELS@|$CHANNEL_ARGS|g" \
      "$REPO/systemd/$f" > "$UNIT_DIR/$f"
done

systemctl --user daemon-reload
systemctl --user enable agent.service
systemctl --user enable --now agent-backup.timer

if [ "${1:-}" != "--no-start" ]; then
  systemctl --user restart agent.service
  echo "$AGENT_NAME is starting. Attach with:  tmux attach -t $SESSION"
else
  echo "Services installed. Start with:  systemctl --user start agent"
fi
