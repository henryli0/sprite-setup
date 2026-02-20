#!/bin/bash
set -e

echo "=== Sprite Setup ==="

# --- GitHub CLI auth ---
echo ""
echo ">> Setting up GitHub CLI authentication..."
if gh auth status &>/dev/null; then
  echo "   Already authenticated."
else
  gh auth login
fi

# --- Claude Code status line ---
echo ""
echo ">> Setting up Claude Code status line..."

mkdir -p ~/.claude

cat > ~/.claude/statusline.sh << 'STATUSLINE'
#!/bin/bash
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // .model.id // "unknown"')
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

bar_width=10
filled=$((pct * bar_width / 100))
empty=$((bar_width - filled))
bar=""
[ "$filled" -gt 0 ] && bar=$(printf "%${filled}s" | tr ' ' '▓')
[ "$empty" -gt 0 ] && bar="${bar}$(printf "%${empty}s" | tr ' ' '░')"

echo "[$model] ${bar} ${pct}%"
STATUSLINE
chmod +x ~/.claude/statusline.sh

# Merge statusLine config into settings.json (preserve existing keys)
if [ -f ~/.claude/settings.json ]; then
  tmp=$(jq '.statusLine = {"type": "command", "command": "~/.claude/statusline.sh"}' ~/.claude/settings.json)
  echo "$tmp" > ~/.claude/settings.json
else
  cat > ~/.claude/settings.json << 'EOF'
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
EOF
fi

echo "   Installed ~/.claude/statusline.sh"
echo "   Updated ~/.claude/settings.json"

# --- Done ---
echo ""
echo "=== Setup complete ==="
