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
dir=$(echo "$input" | jq -r '.workspace.current_dir // ""')
folder="${dir##*/}"
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

# Get GitHub remote repo name if available
repo=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    remote=$(git remote get-url origin 2>/dev/null || true)
    if [ -n "$remote" ]; then
        repo=$(basename "$remote" .git)
    fi
fi

bar_width=10
filled=$((pct * bar_width / 100))
empty=$((bar_width - filled))
bar=""
for ((i=0; i<filled; i++)); do bar+="▓"; done
for ((i=0; i<empty; i++)); do bar+="░"; done

# Build the info section before model
info=""
[ -n "$folder" ] && info="${folder}"
[ -n "$repo" ] && info="${info} (${repo})"
[ -n "$info" ] && info="${info} | "

echo "${info}[$model] ${bar} ${pct}%"
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
