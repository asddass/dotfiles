#!/usr/bin/env bash
set -eo pipefail

echo "🚀 Starting Ubuntu Development Environment Setup..."

# 1. Essential APT Packages & Official GitHub CLI Repository
echo "📦 Updating system and installing base packages..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential curl wget git unzip jq ripgrep fd-find

if ! command -v gh >/dev/null 2>&1; then
  echo "🐙 Installing official GitHub CLI..."
  sudo mkdir -p -m 755 /etc/apt/keyrings
  wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y gh
fi

# 2. Windows PATH Isolation & Git Credentials (WSL only)
if grep -qi microsoft /proc/version 2>/dev/null; then
  WSL_CONF="/etc/wsl.conf"
  if grep -qE '^\s*appendWindowsPath' "$WSL_CONF" 2>/dev/null; then
    echo "⚙️ WSL detected: Windows PATH isolation is already configured."
    WSL_RESTART=1
  else
    echo "⚙️ WSL detected: Configuring Windows PATH isolation in /etc/wsl.conf..."
    if grep -q '^\[interop\]' "$WSL_CONF" 2>/dev/null; then
      sudo sed -i '/^\[interop\]/a appendWindowsPath = false' "$WSL_CONF"
    else
      printf '\n[interop]\nappendWindowsPath = false\n' |
      sudo tee -a "$WSL_CONF" >/dev/null
    fi
  fi

  # Auto-bridge Windows GCM & gh
  gcm_exe="/mnt/c/Program Files/Git/mingw64/bin/git-credential-manager.exe"

  if [ -x "$gcm_exe" ]; then
    echo "🔑 Configuring Git Credential Manager for WSL..."
    git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe"

    gcm_token=$(printf "protocol=https\nhost=github.com\n\n" \
      | GCM_INTERACTIVE=never WSLENV="${WSLENV:+$WSLENV:}GCM_INTERACTIVE" "$gcm_exe" get 2>/dev/null \
      | tr -d '\r' | grep "^password=" | cut -d'=' -f2- || true)

    if [ -n "$gcm_token" ] && printf '%s\n' "$gcm_token" | gh auth login --with-token --hostname github.com >/dev/null 2>&1; then
      echo "✅ gh CLI authenticated via Windows GCM token."
    else
      echo "ℹ GCM token not found in Windows vault. You can run 'gh auth login' manually if needed."
    fi
    unset gcm_token
  else
    echo "ℹ Git Credential Manager not found on Windows host path. Skipping GCM bridge."
  fi
else
  echo "🐧 Native Linux/Dual-boot detected: Skipping WSL isolation."
fi

# 3. Tool Installations (fnm, uv, opencode)
echo "⚡ Installing fnm..."
[ -x "$HOME/.local/share/fnm/fnm" ] || curl -fsSL https://fnm.vercel.app/install | bash

echo "🐍 Installing uv..."
[ -x "$HOME/.local/bin/uv" ] || curl -LsSf https://astral.sh/uv/install.sh | sh

echo "🤖 Installing OpenCode..."
[ -x "$HOME/.opencode/bin/opencode" ] || curl -fsSL https://opencode.ai/v2/install | bash

# 4. Linking bashrc.d modules into .bashrc
DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! grep -q "# dotfiles bashrc.d" ~/.bashrc; then
  echo "📝 Linking bashrc.d into .bashrc..."
  cat >> ~/.bashrc <<EOF

# dotfiles bashrc.d
if [ -d "$DOT/bashrc.d" ]; then
  for f in "$DOT"/bashrc.d/*.sh; do
    [ -r "\$f" ] && . "\$f"
  done
  unset f
else
  echo "dotfiles: $DOT/bashrc.d not found. Re-run linux/ubuntu-dev-bootstrap.sh" >&2
fi
EOF
fi

# Link Windows-side agent skills (WSL only)
if grep -qi microsoft /proc/version 2>/dev/null && [ ! -e "$HOME/.agents" ] && [ ! -L "$HOME/.agents" ]; then
  win_profile="$(cd /mnt/c 2>/dev/null && /mnt/c/Windows/System32/cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r' || true)"
  if [ -n "$win_profile" ]; then
    win_agents="$(wslpath -u "$win_profile")/.agents"
    if [ -d "$win_agents" ]; then
      ln -s "$win_agents" "$HOME/.agents"
      echo "🔗 Linked ~/.agents -> $win_agents"
    else
      echo "[INFO] $win_agents not found. Skipping skills link."
    fi
  else
    echo "[INFO] Could not resolve Windows profile. Skipping skills link."
  fi
fi

# 5. Node.js & pnpm Setup
echo "🟢 Installing Node.js LTS & pnpm..."
export FNM_PATH="$HOME/.local/share/fnm"
export PATH="$FNM_PATH:$PATH"
eval "$(fnm env --shell bash)"

fnm install --lts
fnm default lts-latest
fnm use lts-latest
npm install -g pnpm

echo ""
if [ "${WSL_RESTART:-0}" = 1 ]; then
  echo "⚠️ Close this terminal, run 'wsl --shutdown' in Windows PowerShell, then reopen Ubuntu."
else
  echo "⚠️ Run 'source ~/.bashrc' to apply all changes."
fi
echo ""
