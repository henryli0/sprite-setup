#!/bin/bash
set -e

echo "=== Sprite Setup ==="

OS=$(uname -s)

# --- macOS: Homebrew + dependencies ---
if [ "$OS" = "Darwin" ]; then
  echo ""
  echo ">> Checking Homebrew..."
  if ! command -v brew &>/dev/null; then
    echo "   Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" < /dev/tty
    # Add brew to PATH for the rest of this script
    if [ -x /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
    echo "   Homebrew installed."
  else
    echo "   Already installed."
  fi

  echo ""
  echo ">> Checking dependencies (gh, jq, uv)..."
  for pkg in gh jq uv; do
    if ! command -v "$pkg" &>/dev/null; then
      echo "   Installing $pkg..."
      brew install "$pkg" < /dev/null
    else
      echo "   $pkg already installed."
    fi
  done
else
  # --- Debian/Ubuntu: dependencies ---
  echo ""
  echo ">> Checking dependencies (gh, jq, uv)..."

  if ! command -v jq &>/dev/null; then
    echo "   Installing jq..."
    sudo apt update && sudo apt install -y jq < /dev/null
  else
    echo "   jq already installed."
  fi

  if ! command -v gh &>/dev/null; then
    echo "   Installing gh..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update && sudo apt install -y gh < /dev/null
  else
    echo "   gh already installed."
  fi

  if ! command -v uv &>/dev/null; then
    echo "   Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh < /dev/null
    export PATH="$HOME/.local/bin:$PATH"
  else
    echo "   uv already installed."
  fi
fi

# --- Claude Code ---
echo ""
echo ">> Checking Claude Code..."
if ! command -v claude &>/dev/null; then
  echo "   Installing Claude Code..."
  claude_installer=$(curl -fsSL https://claude.ai/install.sh)
  bash -c "$claude_installer" < /dev/null
  echo "   Claude Code installed."
else
  echo "   Already installed."
fi

# --- Claude Code status line ---
echo ""
echo ">> Setting up Claude Code status line..."

mkdir -p ~/.claude

# Check if statusLine is already configured in settings.json
if [ -f ~/.claude/settings.json ] && jq -e '.statusLine' ~/.claude/settings.json &>/dev/null; then
  existing=$(jq -r '.statusLine.command // (.statusLine | tostring)' ~/.claude/settings.json)
  echo "   statusLine is already configured: $existing"
  read -r -p "   Overwrite it? [y/N] " overwrite_settings < /dev/tty
  if [[ ! "$overwrite_settings" =~ ^[Yy]$ ]]; then
    echo "   Skipping status line setup."
    overwrite_settings="n"
  fi
else
  overwrite_settings="y"
fi

if [[ "$overwrite_settings" =~ ^[Yy]$ ]]; then
  # Check if statusline.sh already exists
  if [ -f ~/.claude/statusline.sh ]; then
    read -r -p "   ~/.claude/statusline.sh already exists. Overwrite it? [y/N] " overwrite_script < /dev/tty
  else
    overwrite_script="y"
  fi

  if [[ "$overwrite_script" =~ ^[Yy]$ ]]; then
    cat > ~/.claude/statusline.sh << 'STATUSLINE'
#!/bin/bash
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // .model.id // "unknown"')
dir=$(echo "$input" | jq -r '.workspace.current_dir // ""')
# Replace home dir with ~ for a shorter path
dir_display=$(echo "$dir" | sed "s|^$HOME|~|")
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

# Build the info section after the bar
info=""
[ -n "$dir_display" ] && info="${dir_display}"
if [ -n "$repo_url" ]; then
    info="${info} (${repo_url})"
elif [ -n "$repo" ]; then
    info="${info} (${repo})"
fi

printf '%b' "[\e[34m${model}\e[0m] ${bar} ${pct}% | ${info}\n"
STATUSLINE
    chmod +x ~/.claude/statusline.sh
    echo "   Installed ~/.claude/statusline.sh"
  else
    echo "   Keeping existing ~/.claude/statusline.sh"
  fi

  # Update settings.json
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
  echo "   Updated ~/.claude/settings.json"
fi

# --- Git config ---
echo ""
echo ">> Setting up Git identity..."
current_name=$(git config --global user.name 2>/dev/null || true)
current_email=$(git config --global user.email 2>/dev/null || true)
if [ -n "$current_name" ] && [ -n "$current_email" ]; then
  echo "   Already configured: $current_name <$current_email>"
  read -r -p "   Change it? [y/N] " change_git < /dev/tty
  if [[ "$change_git" =~ ^[Yy]$ ]]; then
    read -r -p "   Enter your name [$current_name]: " git_name < /dev/tty
    read -r -p "   Enter your email [$current_email]: " git_email < /dev/tty
    git_name="${git_name:-$current_name}"
    git_email="${git_email:-$current_email}"
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    echo "   Git identity set to: $git_name <$git_email>"
  else
    echo "   Keeping existing identity."
  fi
else
  read -r -p "   Enter your name: " git_name < /dev/tty
  read -r -p "   Enter your email: " git_email < /dev/tty
  git config --global user.name "$git_name"
  git config --global user.email "$git_email"
  echo "   Git identity set to: $git_name <$git_email>"
fi

# --- GitHub CLI auth ---
echo ""
echo ">> Setting up GitHub CLI authentication..."
if gh auth status &>/dev/null; then
  echo "   Already authenticated."
else
  gh auth login --web < /dev/tty
fi

# --- glow ---
echo ""
echo ">> Installing glow (markdown renderer)..."
if command -v glow &>/dev/null; then
  echo "   Already installed."
elif [ "$OS" = "Darwin" ]; then
  brew install glow < /dev/null
  echo "   glow installed."
else
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
  echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
  sudo apt update && sudo apt install -y glow < /dev/null
  echo "   glow installed."
fi

# --- Done ---
echo ""
echo "=== Setup complete ==="
