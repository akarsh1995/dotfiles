#!/usr/bin/env fish
# Bootstrap a new machine from this dotfiles repo.
#
#   bootstrap.fish                # install/refresh everything
#   bootstrap.fish --check        # report what is missing, change nothing
#   bootstrap.fish --dry-run      # print the actions without running them
#   bootstrap.fish --skip-brew --skip-font --skip-shell --skip-agents
#
# Safe to re-run: package installs, git config, fisher plugins, and the
# scheduled agents are all idempotent.

set -g email "25827628+akarsh1995@users.noreply.github.com"
set -g gpg_key DBF7D3AFC7E8B220
set -g repo $HOME/.config

set -g DRY_RUN 0
set -g CHECK_ONLY 0
set -g SKIP_BREW 0
set -g SKIP_FONT 0
set -g SKIP_SHELL 0
set -g SKIP_AGENTS 0
set -g INSTALL_FONT 0

for arg in $argv
    switch $arg
        case -n --dry-run
            set DRY_RUN 1
        case -c --check
            set CHECK_ONLY 1
            set DRY_RUN 1
        case --skip-brew
            set SKIP_BREW 1
        case --install-font
            set INSTALL_FONT 1
        case --skip-font
            set SKIP_FONT 1
        case --skip-shell
            set SKIP_SHELL 1
        case --skip-agents
            set SKIP_AGENTS 1
        case -h --help
            echo "usage: bootstrap.fish [--check|--dry-run] [--install-font] [--skip-brew] [--skip-font] [--skip-shell] [--skip-agents]"
            exit 0
        case '*'
            echo "bootstrap.fish: unknown option '$arg'" >&2
            exit 1
    end
end

set -g OS_TYPE (uname -s)

# ------------------------------------------------------------------ helpers
function __say
    echo "==> $argv"
end

function __warn
    echo "warning: $argv" >&2
end

function __run
    if test $DRY_RUN -eq 1
        echo "[dry-run] $argv"
        return 0
    end
    $argv
end

function __missing
    echo "  missing: $argv"
end

# --------------------------------------------------------------- homebrew
set -g BREW_CMD ""
if command -q brew
    set BREW_CMD brew
else if test -f /opt/homebrew/bin/brew
    set BREW_CMD /opt/homebrew/bin/brew
else if test -f /usr/local/bin/brew
    set BREW_CMD /usr/local/bin/brew
else if test -f /home/linuxbrew/.linuxbrew/bin/brew
    set BREW_CMD /home/linuxbrew/.linuxbrew/bin/brew
end

if test -z "$BREW_CMD"
    if test $CHECK_ONLY -eq 1
        __warn "Homebrew not found"
        echo "  install: https://brew.sh"
    else
        echo "Error: Homebrew not found. Install it first: https://brew.sh" >&2
        exit 1
    end
else
    echo "Using Homebrew at: $BREW_CMD"
end

function __install_brew_packages
    set -l manifest $repo/brew/brew-packages
    if not test -f $manifest
        __warn "$manifest not found, skipping package install"
        return 0
    end

    set -l installed_formulae ($BREW_CMD list --formula 2>/dev/null | string trim)
    set -l installed_casks ($BREW_CMD list --cask 2>/dev/null | string trim)

    for raw in (string match -v '^#' <$manifest | string trim)
        test -z "$raw"; and continue
        set -l kind formula
        set -l package $raw
        if string match -q 'cask:*' $raw
            set kind cask
            set package (string replace 'cask:' '' $raw)
        end
        # Manifest may carry a tap prefix; brew list prints the short name.
        set -l short (string replace -r '^[^/]+/[^/]+/' '' $package)

        set -l is_installed 0
        if test $kind = cask
            contains -- $short $installed_casks; and set is_installed 1
        else
            contains -- $short $installed_formulae; and set is_installed 1
        end

        if test $is_installed -eq 1
            echo "  $package already installed"
        else
            __run $BREW_CMD install --$kind $package
        end
    end
end

# ------------------------------------------------------------------- gpg
function __have_gpg_key
    command -q gpg; or return 1
    gpg --list-secret-keys $gpg_key >/dev/null 2>&1
end

function __check_gpg
    if not command -q gpg
        __warn "gpg not installed; encrypted fish/secure files and commit signing will not work"
        return 1
    end
    if not gpg --list-secret-keys $gpg_key >/dev/null 2>&1
        __warn "GPG secret key $gpg_key not found"
        echo "  Import your key backup, then re-run bootstrap:"
        echo "    gpg --import <backup>.asc"
        echo "    gpg --edit-key $gpg_key   # trust -> 5 -> save"
        return 1
    end
    return 0
end

function __configure_gpg_agent
    if test $OS_TYPE != Darwin
        if not command -q pinentry
            __warn "no pinentry found; unattended signed commits may fail on Linux"
        end
        return 0
    end

    if test -n "$BREW_CMD"; and not $BREW_CMD list --formula pinentry-mac >/dev/null 2>&1
        __run $BREW_CMD install pinentry-mac
    end

    set -l conf $HOME/.gnupg/gpg-agent.conf
    if test $DRY_RUN -eq 1
        echo "[dry-run] ensure pinentry-mac + cache TTLs in $conf"
        return 0
    end

    mkdir -p $HOME/.gnupg
    chmod 700 $HOME/.gnupg
    if not test -f $conf
        printf '%s\n' \
            'pinentry-program /opt/homebrew/bin/pinentry-mac' \
            'default-cache-ttl 43200' \
            'max-cache-ttl 43200' \
            >$conf
        chmod 600 $conf
        echo "  wrote $conf"
    else if not grep -q '^pinentry-program' $conf
        __warn "$conf has no pinentry-program"
        echo "  add: pinentry-program /opt/homebrew/bin/pinentry-mac"
    end
end

# ---------------------------------------------------------------------- git
function __configure_git
    __run git config --global user.name "Akarsh Jain"
    __run git config --global user.email $email
    __run git config --global gpg.program gpg
    __run git config --global init.defaultBranch main
    __run git config --global pull.rebase true
    __run git config --global rerere.enabled true

    if __have_gpg_key
        __run git config --global user.signingkey $gpg_key
        __run git config --global commit.gpgsign true
        __run git config --global tag.gpgSign true
    else
        __run git config --global --unset commit.gpgsign
        __run git config --global --unset tag.gpgSign
        __warn "commit signing left off until $gpg_key is imported"
    end

    if test -d $repo/.git
        __run git -C $repo config core.hooksPath scripts/git-hooks
    end
end

# -------------------------------------------------------------------- font
function __install_font
    set -l font_dir ""
    switch $OS_TYPE
        case Darwin
            set font_dir $HOME/Library/Fonts
        case Linux
            set font_dir $HOME/.local/share/fonts
        case '*'
            __warn "unknown OS; skipping font install"
            return 0
    end

    set -l found (find $font_dir -iname 'JetBrainsMono*Nerd*.ttf' 2>/dev/null | head -1)
    if test -n "$found"
        echo "  JetBrainsMono Nerd Font already installed"
        return 0
    end

    if test $INSTALL_FONT -eq 0
        echo "  JetBrainsMono Nerd Font not found"
        echo "  install it later with: bootstrap.fish --install-font"
        echo "  or: brew install --cask font-jetbrains-mono-nerd-font"
        return 0
    end

    if not command -q curl
        __warn "curl is required for the font install; skipping"
        return 0
    end

    # The release archive is ~123 MB. Fetch only the weights a terminal needs.
    set -l dest $font_dir/jet-brains-mono
    set -l base https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/patched-fonts/JetBrainsMono/Ligatures
    set -l names \
        JetBrainsMonoNerdFont-Regular.ttf \
        JetBrainsMonoNerdFont-Bold.ttf \
        JetBrainsMonoNerdFont-Italic.ttf \
        JetBrainsMonoNerdFont-BoldItalic.ttf \
        JetBrainsMonoNerdFontMono-Regular.ttf \
        JetBrainsMonoNerdFontMono-Bold.ttf \
        JetBrainsMonoNerdFontMono-Italic.ttf \
        JetBrainsMonoNerdFontMono-BoldItalic.ttf

    __run mkdir -p $dest
    if test $DRY_RUN -eq 1
        echo "[dry-run] download 8 JetBrainsMono Nerd Font files into $dest"
        return 0
    end

    set -l ok 0
    for name in $names
        if curl -fL --progress-bar --connect-timeout 15 --max-time 180 -o $dest/$name $base/$name
            set ok (math $ok + 1)
        else
            __warn "failed to download $name"
        end
    end

    if test $ok -gt 0
        if test $OS_TYPE = Linux; and command -q fc-cache
            fc-cache -f >/dev/null
        end
        echo "  installed $ok/"(count $names)" JetBrainsMono Nerd Font files in $dest"
    else
        __warn "font download failed; install later with --install-font"
    end
end

# --------------------------------------------------------------------- nnn
function __install_nnn_plugins
    if test -d $HOME/.config/nnn/plugins
        echo "  nnn plugins already present"
        return 0
    end
    if not command -q curl
        __warn "curl not found; skipping nnn plugins"
        return 0
    end
    __run sh -c "curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs | sh"
end

# ------------------------------------------------------------------- fisher
function __sync_fisher_ignores
    set -l script $repo/scripts/sync-fisher-ignores.fish
    if not test -f $script
        __warn "$script missing; plugin files may show up in git status"
        return 1
    end
    set -l fish_bin (command -s fish 2>/dev/null)
    test -n "$fish_bin"; or set fish_bin (status fish-path 2>/dev/null)
    __run $fish_bin $script
end

function __install_fisher_plugins
    set -l manifest $repo/fish/fish_plugins
    if not test -f $manifest
        __warn "$manifest not found; skipping fisher plugins"
        return 0
    end
    if not type -q fisher
        __warn "fisher is not available; install it with: brew install fisher"
        return 1
    end

    set -l installed (fisher list)
    for plugin in (string match -v '^#' <$manifest | string trim)
        test -z "$plugin"; and continue
        if contains -- $plugin $installed
            echo "  $plugin already installed"
        else
            __run fisher install $plugin
        end
    end
end

# -------------------------------------------------------------------- shell
function __set_login_shell
    set -l fish_path (command -s fish 2>/dev/null)
    test -n "$fish_path"; or set fish_path (status fish-path 2>/dev/null)
    if test -z "$fish_path"
        __warn "fish executable not found; skipping default shell setup"
        return 1
    end

    echo "  fish: $fish_path"
    if not grep -qxF $fish_path /etc/shells
        if test $DRY_RUN -eq 1
            echo "[dry-run] add $fish_path to /etc/shells"
        else if sudo -n true 2>/dev/null
            echo $fish_path | sudo tee -a /etc/shells >/dev/null
        else
            __warn "cannot update /etc/shells without a password"
            echo "  run: echo '$fish_path' | sudo tee -a /etc/shells"
        end
    end

    if test "$SHELL" != "$fish_path"
        if test $DRY_RUN -eq 1
            echo "[dry-run] chsh -s $fish_path"
        else if test -t 0
            if chsh -s $fish_path
                echo "  default shell changed; log out and back in to apply"
            else
                __warn "chsh failed; run manually: chsh -s $fish_path"
            end
        else
            echo "  not a terminal; run after install: chsh -s $fish_path"
        end
    else
        echo "  fish is already the default shell"
    end
end

# ------------------------------------------------------------------- agents
function __remove_legacy_cron
    if test $DRY_RUN -eq 1
        echo "[dry-run] remove legacy cron backup entry"
        return 0
    end
    command -q crontab; or return 0
    set -l current (crontab -l 2>/dev/null)
    if not string match -q '*config_auto_commit_and_push*' -- $current
        return 0
    end

    set -l filtered (printf '%s\n' $current | string match -rv 'config_auto_commit_and_push')
    if test (count $filtered) -gt 0
        printf '%s\n' $filtered | crontab -
    else
        crontab -r 2>/dev/null
    end
    echo "  removed legacy cron backup entry"
end

function __install_agents
    set -l installer $repo/scripts/install-launchd.fish
    if not test -f $installer
        __warn "$installer missing; skipping scheduled agents"
        return 1
    end
    set -l fish_bin (command -s fish 2>/dev/null)
    test -n "$fish_bin"; or set fish_bin (status fish-path 2>/dev/null)
    __run $fish_bin $installer all
    __remove_legacy_cron
end

# ------------------------------------------------------------------- verify
function __verify
    set -l rc 0
    __say "Verification"

    set -l bad
    for file in (find $repo/fish -name '*.fish')
        if not fish -n $file >/dev/null 2>&1
            set bad $bad $file
        end
    end
    if test (count $bad) -gt 0
        __warn "fish syntax errors:"
        printf '  %s\n' $bad
        set rc 1
    else
        echo "  fish syntax ok"
    end

    if type -q fisher
        echo "  fisher plugins: "(count (fisher list))" installed"
    else
        __warn "fisher not available"
        set rc 1
    end

    if test -f $repo/scripts/sync-fisher-ignores.fish
        if fish $repo/scripts/sync-fisher-ignores.fish --check >/dev/null 2>&1
            echo "  fisher ignore block current"
        else
            __warn "fisher ignore block is stale (run scripts/sync-fisher-ignores.fish)"
            set rc 1
        end
    end

    if test -d $repo/.git
        echo "  repo: "(git -C $repo status --short --branch | head -1)
    end

    if test $OS_TYPE = Darwin
        if launchctl print gui/(id -u)/com.akarsh.autobackup >/dev/null 2>&1
            echo "  autobackup agent loaded"
        else
            __warn "com.akarsh.autobackup is not loaded"
            set rc 1
        end
    else if command -q systemctl
        if systemctl --user is-enabled dotfiles-autobackup.timer >/dev/null 2>&1
            echo "  autobackup timer enabled"
        else
            __warn "dotfiles-autobackup.timer is not enabled"
            set rc 1
        end
    end

    return $rc
end

# --------------------------------------------------------------------- main
__say "Bootstrap on $OS_TYPE"(test $DRY_RUN -eq 1; and echo " (dry run)")

if test $SKIP_BREW -eq 0; and test -n "$BREW_CMD"
    __say "Homebrew packages"
    __install_brew_packages
end

if test $SKIP_FONT -eq 0
    __say "Fonts"
    __install_font
end

__say "GPG"
__configure_gpg_agent

__say "Git configuration"
__configure_git

__say "nnn plugins"
__install_nnn_plugins

__say "Fisher plugins"
__install_fisher_plugins
__sync_fisher_ignores

if test $SKIP_SHELL -eq 0
    __say "Default shell"
    __set_login_shell
end

if test $SKIP_AGENTS -eq 0
    __say "Scheduled agents"
    __install_agents
end

if test $CHECK_ONLY -eq 0; and test $DRY_RUN -eq 0
    __verify
else
    __say "Check complete (no changes made)"
end

if __have_gpg_key
    __say "Reminder: unlock the GPG key once and choose 'Save in Keychain' in pinentry-mac"
    echo "  Hourly backups sign commits; without a cached passphrase they will pause until you unlock it."
end

echo
echo "Done. Logs: $repo/scripts/autobackup.log and $repo/scripts/launchd.cleanup.log"
echo "Manual backup: config-backup    Status: config-backup status"