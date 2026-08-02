# AgentWake 🌅

**Turn Claude Code into a persistent AI agent — with a name, a brain that learns over time, and Discord access — running on your Mac.**

One file. You feed it to Claude Code, and it walks you through building your own always-on AI agent, step by step, in about 15 minutes.

> Claude Code gives you the wires. AgentWake gives you the brain.

<!-- Add a short demo GIF here — it's the single highest-leverage thing on this page.
![AgentWake demo](docs/demo.gif) -->

## What it is

AgentWake is a single guided Markdown file (**[`agentwake.md`](agentwake.md)**). You open Claude Code, hand it the file, and it becomes an interactive setup wizard that builds you a **persistent AI agent** — one that:

- **Has an identity** — a name, values, a way of thinking, and a voice that stay consistent across every conversation.
- **Has a brain that learns** — a structured knowledge base (learnings, corrections, a journal, project notes, a profile of you) it reads on startup and updates as it goes, so it gets more useful over time instead of forgetting everything.
- **Lives on Discord** — talk to it from your phone, anywhere. It runs in a `tmux` session on your Mac: always on, always reachable.
- **Improves itself** — it records what it learns and where it was wrong, then applies that next time.

It's the open-source version of the setup behind **Enzo**, the persistent agent I run day to day.

## Quickstart

**Requirements:** macOS 13+, a **Claude Pro or Max** subscription, and ~15 minutes.

1. Download **[`agentwake.md`](agentwake.md)** (or clone this repo).
2. In a terminal, start Claude Code:
   ```sh
   claude
   ```
3. Point it at the guide:
   ```
   Read agentwake.md and walk me through it.
   ```
4. Follow along. It installs the prerequisites (Homebrew, Bun, tmux, GitHub CLI, the Claude Code CLI), helps you create a Discord bot, builds your agent's brain, writes its `CLAUDE.md`, and launches it in a persistent session.

You'll be chatting with your agent on Discord by the end.

## What gets built (the "brain")

The setup creates a structured brain your agent reads on every boot and updates in real time:

| File | What it holds |
|---|---|
| `Index` | Map of the brain + how the agent uses it |
| `Identity` | Who the agent is — values, voice, boundaries |
| `How I Think` | Reasoning approach + known blind spots |
| `Capabilities` | What it can/can't do, its tools, how it grows |
| `Learnings` / `Corrections` | What it's learned; where it was wrong |
| `Conversation Log` / `Journal` | Memory across sessions |
| `Active Projects` / `Project Ideas` | What it's working on |
| `<You>` | A profile of you — preferences, context |

…plus a permanent `CLAUDE.md` that ties it all together and a `tmux` launch setup so it stays running.

## ⚠️ A note on safety

This gives your agent **full access to the machine** — files, terminal, browser, network — without approving each action. That autonomy is the point, but it means mistakes can have real consequences. Run it on a **dedicated machine** (not your primary workstation), keep backups, and only pair **trusted** people on Discord.

## License

MIT — see [LICENSE](LICENSE). Use it, fork it, build on it.

## About

Built by **Benji Banwart**. I build AI agents — from personal setups like this one to production systems running real businesses. AgentWake is the open-source version of the setup I run myself.

→ [benjibanwart.dev](https://benjibanwart.dev) · [@benjibanwart](https://x.com/benjibanwart)

If it's useful to you, a ⭐ helps others find it. Ideas or improvements? Open an issue or PR.
