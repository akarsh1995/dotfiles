#!/usr/bin/env fish

set -x email "25827628+akarsh1995@users.noreply.github.com"

set gpg_key DBF7D3AFC7E8B220

# Find the correct brew path
if command -v brew &>/dev/null
    set BREW_CMD brew
else if test -f /opt/homebrew/bin/brew
    set BREW_CMD /opt/homebrew/bin/brew
else if test -f /usr/local/bin/brew
    set BREW_CMD /usr/local/bin/brew
else if test -f /home/linuxbrew/.linuxbrew/bin/brew
    set BREW_CMD /home/linuxbrew/.linuxbrew/bin/brew
else
    echo "Error: Homebrew not found. Please install Homebrew first."
    exit 1
end

echo "Using Homebrew at: $BREW_CMD"

# install brew packages
if test -f $HOME/.config/brew/brew-packages
    set installed_packages ( $BREW_CMD list --formula | sed 's/@.*//' )
    for package in (cat $HOME/.config/brew/brew-packages)
        if not contains $package $installed_packages
            $BREW_CMD install $package
        else
            echo "$package is already installed"
        end
    end
else
    echo "brew-packages file not found, skipping brew packages installation"
end

# Install JetBrainsMono Nerd Font if not already installed
echo "Checking for JetBrainsMono Nerd Font..."

# Detect OS and set font directory
set OS_TYPE (uname -s)
switch $OS_TYPE
    case Darwin
        set FONT_DIR "$HOME/Library/Fonts"
    case Linux
        set FONT_DIR "$HOME/.local/share/fonts"
        mkdir -p $FONT_DIR
    case '*'
        echo "Unknown OS, skipping font installation"
        set FONT_DIR ""
end

if test -n "$FONT_DIR"
    # Check if font is already installed
    if test (count $FONT_DIR/JetBrainsMono*Nerd*.ttf 2>/dev/null) -eq 0
        echo "Installing JetBrainsMono Nerd Font..."
        
        # Download font
        set TEMP_DIR (mktemp -d)
        curl -L -o $TEMP_DIR/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip
        
        # Extract and install
        unzip -q $TEMP_DIR/JetBrainsMono.zip -d $TEMP_DIR/JetBrainsMono
        cp $TEMP_DIR/JetBrainsMono/*.ttf $FONT_DIR/
        
        # Update font cache on Linux
        if test "$OS_TYPE" = "Linux"
            fc-cache -fv
        end
        
        # Cleanup
        rm -rf $TEMP_DIR
        
        echo "JetBrainsMono Nerd Font installed successfully"
    else
        echo "JetBrainsMono Nerd Font is already installed"
    end
end

begin
    # This script sets up a cron jobs to automatically commit and push changes to the .config directory every hour.
    # echo "0 18 * * * $(which fish) -c 'cd $HOME/.config && if test (git status --short | wc -l) -gt 0; git add -A; git commit -m \"\$(date +'\%Y-\%m-\%d')\"; git push origin main; end'"
    echo "0 18 * * * $(which fish) -c config_auto_commit_and_push"
    echo "0 0 * * * $(which docker) container prune -f"
end | crontab -

# This script sets up a git configuration file with user information.
echo "
[user]
  name = Akarsh Jain
  email = $email
  signingkey = $gpg_key
[commit]
	gpgsign = true
[gpg]
	program = gpg
[tag]
	gpgSign = true
" >$HOME/.gitconfig

# install nnn plugins if plugins directory empty
if test ! -d $HOME/.config/nnn/plugins
    echo "Installing nnn plugins..."
    sh -c "$(curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs)"
else
    echo "nnn plugins already installed"
end

# install fisher plugins from fish_plugins file if plugin is not installed in fisher list
if test -f $HOME/.config/fish/fish_plugins
    echo "Installing fisher plugins..."
    # Install plugins from fish_plugins file
    set installed_plugins (fisher list)

    for plugin in (cat $HOME/.config/fish/fish_plugins)
        # Check if the plugin is already installed
        if not contains $plugin $installed_plugins
            # Install the plugin using fisher
            echo "Installing $plugin..."
            fisher install $plugin
        else
            echo "$plugin is already installed"
        end
    end
else
    echo "fish_plugins file not found, skipping fisher plugins installation"
end

# Set fish as default shell
set FISH_PATH (which fish)
if test -n "$FISH_PATH"
    echo "Fish executable found at: $FISH_PATH"
    echo "Setting fish as default shell..."
    
    # Check if fish is already in /etc/shells
    if not grep -q "^$FISH_PATH\$" /etc/shells
        echo "Adding fish to /etc/shells..."
        echo $FISH_PATH | sudo tee -a /etc/shells
    end
    
    # Check if fish is already the default shell
    if test "$SHELL" != "$FISH_PATH"
        echo "Changing default shell to fish..."
        chsh -s $FISH_PATH
        echo "Default shell changed to fish. Please log out and log back in for changes to take effect."
    else
        echo "Fish is already the default shell"
    end
else
    echo "Error: Could not find fish executable"
end
