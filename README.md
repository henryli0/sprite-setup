# sprite-setup

Setup script for new Sprite VMs.

## Usage

```bash
curl -fsSL https://raw.githubusercontent.com/henryli0/sprite-setup/main/setup.sh | bash
```

## What it does

- **Homebrew** *(macOS only)* — installs Homebrew if not present
- **Dependencies** — installs `gh` (GitHub CLI) and `jq` via Homebrew on macOS or apt on Debian/Ubuntu
- **GitHub CLI auth** — runs `gh auth login` (skips if already authenticated)
- **Claude Code status line** — installs a status line script showing model name, context window usage, and current repo
- **glow** — installs the [glow](https://github.com/charmbracelet/glow) terminal markdown renderer
