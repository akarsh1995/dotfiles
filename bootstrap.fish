#!/usr/bin/env fish

set -x email "25827628+akarsh1995@users.noreply.github.com"

set gpg_key DBF7D3AFC7E8B220

# if not brew installed already then install it
if test ! -f /opt/homebrew/bin/brew
    echo "Installing Homebrew..."

    # Install Homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
end

# install brew packages
if test -f $HOME/.config/brew/brew-packages
    set installed_packages ( /opt/homebrew/bin/brew list --formula | sed 's/@.*//' )
    for package in (cat $HOME/.config/brew/brew-packages)
        if not contains $package $installed_packages
            sudo -v
            /opt/homebrew/bin/brew install $package
        else
            echo "$package is already installed"
        end
    end
else
    echo "brew-packages file not found, skipping brew packages installation"
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
            fisher add $plugin
        else
            echo "$plugin is already installed"
        end
    end
else
    echo "fish_plugins file not found, skipping fisher plugins installation"
end
