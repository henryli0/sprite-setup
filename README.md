# sprite-setup

Setup script for new Sprite VMs.

## Usage

```bash
curl -fsSL https://raw.githubusercontent.com/henryli0/sprite-setup/main/setup.sh | bash
```

## What it does

- **Homebrew** *(macOS only)* — installs Homebrew if not present
- **Dependencies** — installs `gh` (GitHub CLI), `jq`, and `uv` (Python package manager) via Homebrew on macOS or apt/curl on Debian/Ubuntu
- **Claude Code** — installs [Claude Code](https://claude.ai) CLI if not present
- **Claude Code status line** — installs a status line script showing model name, context window usage, and current repo
- **Git config** — prompts for `user.name` and `user.email` if not already set
- **GitHub CLI auth** — runs `gh auth login` (skips if already authenticated)
- **glow** — installs the [glow](https://github.com/charmbracelet/glow) terminal markdown renderer
