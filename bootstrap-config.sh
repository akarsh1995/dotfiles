#!/bin/bash

sudo -v

# Script to clone the .config repository and bootstrap the configuration

# Variables
REPO_URL="https://github.com/akarsh1995/dotfiles" # Replace with your repository URL
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup"

# Detect OS
OS="$(uname -s)"
case "$OS" in
  Linux*)  OS_TYPE="Linux";;
  Darwin*) OS_TYPE="macOS";;
  *)       OS_TYPE="Unknown";;
esac

echo "Detected OS: $OS_TYPE"

# Add Homebrew to PATH if it exists (needed for Linux)
if [ -d "/home/linuxbrew/.linuxbrew/bin" ]; then
  export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
fi
if [ -d "/opt/homebrew/bin" ]; then
  export PATH="/opt/homebrew/bin:$PATH"
fi
if [ -d "/usr/local/bin" ]; then
  export PATH="/usr/local/bin:$PATH"
fi

# Helper function to find or install Homebrew
ensure_brew() {
  if command -v brew &>/dev/null; then
    BREW_CMD="brew"
  elif [ -f "/opt/homebrew/bin/brew" ]; then
    BREW_CMD="/opt/homebrew/bin/brew"
  elif [ -f "/usr/local/bin/brew" ]; then
    BREW_CMD="/usr/local/bin/brew"
  elif [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    BREW_CMD="/home/linuxbrew/.linuxbrew/bin/brew"
  else
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # After installation, determine the correct path
    if [ -f "/opt/homebrew/bin/brew" ]; then
      BREW_CMD="/opt/homebrew/bin/brew"
    elif [ -f "/usr/local/bin/brew" ]; then
      BREW_CMD="/usr/local/bin/brew"
    elif [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
      BREW_CMD="/home/linuxbrew/.linuxbrew/bin/brew"
    else
      echo "Error: Homebrew installation failed."
      exit 1
    fi
  fi
  echo "Using Homebrew at: $BREW_CMD"
}

# Step 1: Backup existing .config directory
if [ -d "$CONFIG_DIR" ]; then
  echo "Backing up existing .config directory to $BACKUP_DIR..."
  mv "$CONFIG_DIR" "$BACKUP_DIR"
fi

# Step 2: Ensure git is installed
if ! command -v git &>/dev/null; then
  echo "Git is not installed. Installing..."
  ensure_brew
  $BREW_CMD install git
else
  echo "Git is already installed."
fi

# Step 3: Clone the repository
echo "Cloning the configuration repository..."
git clone "$REPO_URL" "$CONFIG_DIR"

# Step 4: Install Fish shell if not already installed
if ! command -v fish &>/dev/null; then
  echo "Installing Fish shell..."
  ensure_brew
  $BREW_CMD install fish
else
  echo "Fish shell is already installed."
fi

# Step 5: Bootstrap the configuration
if [ -f "$CONFIG_DIR/bootstrap.fish" ]; then
  echo "Running bootstrap script..."
  fish "$CONFIG_DIR/bootstrap.fish"
else
  echo "No bootstrap script found. Configuration setup complete."
fi

echo "Configuration successfully bootstrapped!"