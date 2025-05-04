begin
    crontab -l 2>/dev/null
    # This script sets up a cron jobs to automatically commit and push changes to the .config directory every hour.
    echo "0 * * * * $(which fish) -c 'cd $HOME/.config && if test (git status --short | wc -l) -gt 0; git add -A; git commit -m \"\$(date +'\%Y-\%m-\%d')\"; git push origin main; end'"
    echo "0 0 * * * $(which docker) container prune -f"
end | crontab -

# This script sets up a git configuration file with user information.
echo "[user]
name = Akarsh Jain
email = akarsh.1995.02@gmail.com" >$HOME/.gitconfig

# install nnn plugins
sh -c "$(curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs)"

# install fisher plugins from fish_plugins file
if test -f $HOME/.config/fish/fish_plugins
    for plugin in (cat $HOME/.config/fish/fish_plugins)
        fisher add $plugin
    end
else
    echo "fish_plugins file not found skipping fisher plugins installation"
end
