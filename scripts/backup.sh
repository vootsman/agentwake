#!/usr/bin/env bash
# Commits any changes in the agent repo (mostly the brain) and pushes them.
# Run hourly by agent-backup.timer; safe to run by hand any time.
set -euo pipefail
cd "$(dirname "$0")/.."

git add -A
if ! git diff --cached --quiet; then
  git commit -q -m "auto-backup $(date '+%F %H:%M')"
fi
if git remote get-url origin >/dev/null 2>&1; then
  git push -q origin HEAD
else
  echo "No 'origin' remote set — changes committed locally only." >&2
fi
