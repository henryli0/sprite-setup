# spriteconfig

Setup script for new Sprite VMs.

## Usage

```bash
curl -fsSL https://raw.githubusercontent.com/henryli0/spriteconfig/main/setup.sh | bash
```

## What it does

- **GitHub CLI auth** — runs `gh auth login` (skips if already authenticated)
- **Claude Code status line** — installs a status line showing model name and context window usage
