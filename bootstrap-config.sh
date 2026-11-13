#!/bin/bash
# One-shot installer for a new machine.
#
#   curl -sS https://raw.githubusercontent.com/akarsh1995/dotfiles/main/bootstrap-config.sh | bash
#   REPO_URL=git@github.com:akarsh1995/dotfiles.git BRANCH=main ./bootstrap-config.sh
#
# Existing ~/.config is moved to a timestamped backup, never deleted.

set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/akarsh1995/dotfiles}"
BRANCH="${BRANCH:-main}"
CONFIG_DIR="$HOME/.config"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/.config-backup-$STAMP"

say() { printf '==> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }

OS="$(uname -s)"
case "$OS" in
  Darwin) OS_TYPE="macOS" ;;
  Linux) OS_TYPE="Linux" ;;
  *) echo "Unsupported OS: $OS" >&2; exit 1 ;;
esac
say "Detected $OS_TYPE"

# ---------------------------------------------------------------- git
if ! command -v git >/dev/null 2>&1; then
  if [ "$OS_TYPE" = "Linux" ]; then
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update && sudo apt-get install -y git
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y git
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -Sy --noconfirm git
    else
      echo "Install git first, then re-run." >&2
      exit 1
    fi
  else
    echo "Install the Xcode Command Line Tools (xcode-select --install), then re-run." >&2
    exit 1
  fi
fi

# ------------------------------------------------------------ homebrew
export PATH="/opt/homebrew/bin:/usr/local/bin:/home/linuxbrew/.linuxbrew/bin:$PATH"

BREW_CMD=""
if command -v brew >/dev/null 2>&1; then
  BREW_CMD="$(command -v brew)"
elif [ -x /opt/homebrew/bin/brew ]; then
  BREW_CMD=/opt/homebrew/bin/brew
elif [ -x /usr/local/bin/brew ]; then
  BREW_CMD=/usr/local/bin/brew
elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  BREW_CMD=/home/linuxbrew/.linuxbrew/bin/brew
fi

if [ -z "$BREW_CMD" ]; then
  say "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [ -x "$candidate" ]; then
      BREW_CMD="$candidate"
      break
    fi
  done
fi

if [ -z "$BREW_CMD" ]; then
  echo "Homebrew installation failed. Install it from https://brew.sh and re-run." >&2
  exit 1
fi
say "Using Homebrew at $BREW_CMD"

# -------------------------------------------------------------- clone
if [ -d "$CONFIG_DIR/.git" ]; then
  say "$CONFIG_DIR is already a git repository; skipping clone"
  git -C "$CONFIG_DIR" fetch --all --prune || warn "fetch failed; continuing with the local checkout"
else
  if [ -e "$CONFIG_DIR" ]; then
    say "Backing up existing $CONFIG_DIR to $BACKUP_DIR"
    mv "$CONFIG_DIR" "$BACKUP_DIR"
  fi
  say "Cloning $REPO_URL ($BRANCH)"
  git clone --branch "$BRANCH" "$REPO_URL" "$CONFIG_DIR"
fi

# --------------------------------------------------------------- fish
if ! command -v fish >/dev/null 2>&1; then
  say "Installing fish"
  "$BREW_CMD" install fish
  export PATH="$(dirname "$BREW_CMD"):$PATH"
fi

if ! command -v fish >/dev/null 2>&1; then
  echo "fish is still not on PATH. Open a new shell or add Homebrew to PATH, then run:" >&2
  echo "  fish $CONFIG_DIR/bootstrap.fish" >&2
  exit 1
fi

say "Running bootstrap.fish"
exec fish "$CONFIG_DIR/bootstrap.fish" "$@"