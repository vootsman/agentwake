# AgentWake: Linux / VM edition

A Linux port of [AgentWake](https://github.com/BenjaminBanwart/agentwake) (MIT) by Benjamin Banwart. It builds a persistent Claude Code agent with a name, a markdown "brain", and Discord access, running on **Ubuntu Server 24.04** instead of a Mac.

Compared with the original:

| Original (Mac) | This edition |
|---|---|
| Homebrew installs | `bootstrap.sh` (apt + official installers) |
| `caffeinate` + manual tmux launch | systemd service: starts on boot, restarts if it crashes |
| Brain in `~/Documents` | Brain in `~/agent/brain`, backed up hourly to a private GitHub repo |
| Turn off auto-updates | Not needed: security updates are fine because the service restarts the agent after a reboot |
| One machine | **Portable**: rebuild on TrueNAS, a cloud server, or a new PC from the backup repo |

## What's in here

```
agentwake-linux.md        The setup guide Claude Code follows (setup + restore)
bootstrap.sh              Installs tmux, git, gh, Bun, Claude Code; enables always-on services
scripts/init-agent.sh     Creates the brain, CLAUDE.md and agent.conf from templates
scripts/install-services.sh  Installs the systemd service + hourly backup timer
scripts/backup.sh         Commit and push ~/agent (run by the timer)
systemd/                  Service and timer templates
templates/                Brain files and CLAUDE.md template
```

Once set up, `~/agent` also contains `agent.conf`, `CLAUDE.md`, and `brain/`, and that whole folder *is* your agent.

---

> **Looking for the original Mac version?** It's unchanged in [`agentwake.md`](agentwake.md), and its README is [`README-mac.md`](README-mac.md).

## 1. Create the VM

**Windows 11 Pro → follow [docs/hyper-v-ubuntu-vm.md](docs/hyper-v-ubuntu-vm.md)**, a step-by-step guide to an always-on Ubuntu Server VM on Hyper-V that starts with Windows.

Any other hypervisor (VMware, VirtualBox, Proxmox, TrueNAS) works too: **Ubuntu Server 24.04 LTS**, 2 vCPU, 4 GB RAM, 40 GB disk, bridged network, with **OpenSSH server** ticked during install. Take a snapshot once it's installed.

## 2. Get the files onto the VM

SSH in from Windows Terminal (`ssh YOURUSER@VM-IP`), then:

```bash
git clone https://github.com/vootsman/agentwake.git ~/agent
bash ~/agent/bootstrap.sh
source ~/.bashrc
```

(This repo is public and holds no personal data. During setup the agent's own copy is disconnected from it and backed up to a separate **private** repo instead.)

## 3. Run the guided setup

```bash
cd ~/agent
claude
```

Sign in with your Claude Pro/Max account when asked. On a headless VM it shows a link; open it on your phone or PC and paste the code back. Then say:

> Read agentwake-linux.md and walk me through it.

About 15 minutes later you have a named agent on Discord, with its brain backed up to a private GitHub repo.

## Day-to-day

| | |
|---|---|
| See/talk to it in the terminal | `tmux attach -t <session>` (detach: Ctrl+B, D) |
| Restart / stop | `systemctl --user restart agent` / `stop agent` |
| Logs | `journalctl --user -u agent` |
| Back up now | `~/agent/scripts/backup.sh` |
| Update Claude Code | Updates itself; restart the agent to pick up a new version |

---

## Moving your agent (TrueNAS, cloud, new PC)

The VM disk doesn't have to move. Your agent is the private repo plus the Discord bot token in your password manager.

1. **New host:** create an Ubuntu Server 24.04 VM.
   - *TrueNAS SCALE:* Virtualization / VMs → add VM → Ubuntu Server ISO. (The menus differ between TrueNAS releases; check the docs for yours.)
   - *Cloud:* any small Ubuntu 24.04 server, about 2 vCPU / 4 GB. No inbound ports are needed except SSH, since Discord connections are outbound.
2. **Old host:** `~/agent/scripts/backup.sh`, then `systemctl --user stop agent && systemctl --user disable agent`.
3. **New host:**
   ```bash
   sudo apt-get update && sudo apt-get install -y gh git
   gh auth login
   gh repo clone YOUR-GITHUB-NAME/YOUR-AGENT-REPO ~/agent
   bash ~/agent/bootstrap.sh && source ~/.bashrc
   cd ~/agent && claude
   ```
   Say *"Read agentwake-linux.md"*. It detects the existing `agent.conf`, runs **Restore Mode**, asks for the bot token, and walks you through re-pairing.

Run only one copy at a time: two machines on the same bot token will both reply.

## Safety notes

- The agent runs with `--dangerously-skip-permissions`, so it can do anything your VM user can. The VM boundary is what protects the rest of your network and files. Don't mount your NAS shares or home folders into it unless you mean to.
- Keep patient or other sensitive data off the VM. The template `CLAUDE.md` tells the agent not to store protected health information, but treat that as a guardrail, not a guarantee.
- The bot token is never committed (see `.gitignore`). It lives only in `~/.claude/channels/discord/.env` and your password manager.
- Keep the backup repo **private**. Your brain files will gradually contain personal context.

## License

MIT. Original AgentWake © 2026 Benjamin Banwart; Linux adaptation built on it under the same license.
