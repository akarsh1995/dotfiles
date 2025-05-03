#!/bin/bash

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

# Step 3: Bootstrap the configuration
if [ -f "$CONFIG_DIR/bootstrap.fish" ]; then
  echo "Running bootstrap script..."
  fish "$CONFIG_DIR/bootstrap.fish"
else
  echo "No bootstrap script found. Configuration setup complete."
fi

echo "Configuration successfully bootstrapped!"
