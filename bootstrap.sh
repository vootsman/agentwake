#!/usr/bin/env bash
# AgentWake-Linux bootstrap: installs everything the agent needs on a fresh
# Ubuntu Server 24.04 machine. Safe to run more than once.
set -euo pipefail

say() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }

if [ "$(id -u)" -eq 0 ]; then
  echo "Run this as your normal user (it will ask for sudo when needed), not as root." >&2
  exit 1
fi

# Files uploaded through GitHub's website lose their executable bit; restore it.
chmod +x "$(dirname "$0")"/bootstrap.sh "$(dirname "$0")"/scripts/*.sh

say "Installing system packages (tmux, git, curl, unzip, GitHub CLI, python3)"
sudo apt-get update -y
sudo apt-get install -y tmux git curl unzip ca-certificates gh python3

say "Installing Bun (runtime for the Discord plugin)"
if ! command -v bun >/dev/null 2>&1 && [ ! -x "$HOME/.bun/bin/bun" ]; then
  curl -fsSL https://bun.sh/install | bash
else
  echo "Bun already installed."
fi

say "Installing Claude Code CLI (native installer)"
if ! command -v claude >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/claude" ]; then
  curl -fsSL https://claude.ai/install.sh | bash
else
  echo "Claude Code already installed."
fi

say "Making sure ~/.local/bin and ~/.bun/bin are on PATH"
PATH_LINE='export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"'
grep -qxF "$PATH_LINE" "$HOME/.bashrc" || echo "$PATH_LINE" >> "$HOME/.bashrc"
export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"

say "Letting your user services run without being logged in (needed for always-on)"
sudo loginctl enable-linger "$USER"

say "Versions"
echo "tmux:   $(tmux -V)"
echo "git:    $(git --version)"
echo "gh:     $(gh --version | head -1)"
echo "bun:    $(bun --version 2>/dev/null || echo 'open a new shell to see')"
echo "claude: $(claude --version 2>/dev/null || echo 'open a new shell to see')"

say "Bootstrap complete. Open a new terminal (or run: source ~/.bashrc) before continuing."
