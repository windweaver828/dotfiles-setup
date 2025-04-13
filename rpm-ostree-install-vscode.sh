#!/usr/bin/env bash
set -euo pipefail

# Helper: print to stderr and exit
die() {
  echo "Error: $*" >&2
  exit 1
}

# 1) Ensure rpm-ostree is available
if ! command -v rpm-ostree &>/dev/null; then
  die "rpm-ostree not found. Are you on Atomic Fedora (Silverblue/Kinoite/...)?"
fi

# 2) Check if 'code' is already installed
if command -v code &>/dev/null; then
  echo "✔ Visual Studio Code is already installed."
  exit 0
fi

# 3) Ask user
read -rp "Visual Studio Code is not installed. Install now? [y/N] " REPLY
if [[ ! "$REPLY" =~ ^[Yy] ]]; then
  echo "Installation aborted."
  exit 0
fi

# 4) Add VS Code repo if missing
REPO_FILE=/etc/yum.repos.d/vscode.repo
REPO_URL=https://packages.microsoft.com/yumrepos/vscode.repo
KEY_URL=https://packages.microsoft.com/keys/microsoft.asc

if ! grep -q '^\[code\]' "$REPO_FILE" 2>/dev/null; then
  echo "→ Importing Microsoft GPG key…"
  sudo rpm --import "$KEY_URL"
  :contentReference[oaicite:0]{index=0}

  echo "→ Adding VS Code repository…"
  # Use dnf config-manager if available
  if command -v dnf &>/dev/null && dnf config-manager --help &>/dev/null; then
    sudo dnf config-manager --add-repo "$REPO_URL"
  else
    # layer in dnf-plugins-core so we can use config-manager
    sudo rpm-ostree install dnf-plugins-core
    sudo dnf config-manager --add-repo "$REPO_URL"
  fi
  :contentReference[oaicite:1]{index=1}
else
  echo "→ VS Code repository already present."
fi

# 5) Layer in 'code'
echo "→ Layering in Visual Studio Code…"
sudo rpm-ostree install code

echo
echo "✔ Done! Please reboot to apply changes:"
echo "    sudo systemctl reboot"
