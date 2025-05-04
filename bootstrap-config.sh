#!/bin/bash

sudo -v

# Script to clone the .config repository and bootstrap the configuration

# Variables
REPO_URL="https://github.com/akarsh1995/dotfiles" # Replace with your repository URL
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup"

# Step 1: Backup existing .config directory
if [ -d "$CONFIG_DIR" ]; then
  echo "Backing up existing .config directory to $BACKUP_DIR..."
  mv "$CONFIG_DIR" "$BACKUP_DIR"
fi

# Step 2: Clone the repository
echo "Cloning the configuration repository..."
git clone "$REPO_URL" "$CONFIG_DIR"

# Step 3: Install Homebrew if not already installed
if ! command -v /opt/homebrew/bin/brew &>/dev/null; then
  echo "Installing Homebrew..."
  # Install Homebrew
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install Fish shell if not already installed
if ! command -v fish &>/dev/null; then
  echo "Installing Fish shell..."
  # Install Fish shell
  brew install fish
else
  echo "Fish shell is already installed."
fi

# Step 4: Bootstrap the configuration
if [ -f "$CONFIG_DIR/bootstrap.fish" ]; then
  echo "Running bootstrap script..."
  fish "$CONFIG_DIR/bootstrap.fish"
else
  echo "No bootstrap script found. Configuration setup complete."
fi

echo "Configuration successfully bootstrapped!"
