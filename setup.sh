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

# Get GitHub remote repo name and URL if available
repo=""
repo_url=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    remote=$(git remote get-url origin 2>/dev/null || true)
    if [ -n "$remote" ]; then
        repo=$(basename "$remote" .git)
        # Convert SSH URL to HTTPS for clickable link
        repo_url=$(echo "$remote" | sed 's|git@github.com:|https://github.com/|' | sed 's|\.git$||')
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
if [ -n "$repo" ] && [ -n "$repo_url" ]; then
    # OSC 8 clickable link: \e]8;;URL\aTEXT\e]8;;\a
    info="${info} (\e]8;;${repo_url}\a${repo}\e]8;;\a)"
elif [ -n "$repo" ]; then
    info="${info} (${repo})"
fi
[ -n "$info" ] && info="${info} "

printf '%b' "${info}[$model] ${bar} ${pct}%\n"
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
