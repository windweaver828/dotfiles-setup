#!/usr/bin/env bash
set -euo pipefail

# Check if rpm-ostree is available
if ! command -v rpm-ostree &>/dev/null; then
  echo "rpm-ostree not found. Are you on Fedora Silverblue/Kinoite?"
  exit 1
fi

# Check if 'code' is already installed
if command -v code &>/dev/null; then
  echo "✔ Visual Studio Code is already installed."
  exit 0
fi

# Prompt the user
read -rp "Visual Studio Code is not installed. Install now? [y/N] " REPLY
if [[ ! "$REPLY" =~ ^[Yy] ]]; then
  echo "Installation aborted."
  exit 0
fi

# Add VS Code repository if missing
REPO_FILE=/etc/yum.repos.d/vscode.repo
REPO_URL=https://packages.microsoft.com/yumrepos/vscode
KEY_URL=https://packages.microsoft.com/keys/microsoft.asc

if [[ ! -f "$REPO_FILE" ]]; then
  echo "→ Adding VS Code repository..."
  sudo bash -c "cat > $REPO_FILE <<EOF
[code]
name=Visual Studio Code
baseurl=$REPO_URL
enabled=1
gpgcheck=1
gpgkey=$KEY_URL
EOF"
else
  echo "→ VS Code repository already present."
fi

# Layer in 'code'
echo "→ Layering in Visual Studio Code..."
sudo rpm-ostree install code

echo
echo "✔ Done! Please reboot to apply changes:"
echo "    sudo systemctl reboot"
