# Compatibility wrapper. The real logic lives in scripts/autobackup.fish so it
# can also be invoked by launchd / systemd without relying on function autoload.

function config_auto_commit_and_push --description "Commit and push ~/.config (hourly safety net)"
    set -l fish_bin (command -s fish 2>/dev/null)
    test -n "$fish_bin"; or set fish_bin (status fish-path 2>/dev/null)
    test -n "$fish_bin"; or set fish_bin fish
    $fish_bin $HOME/.config/scripts/autobackup.fish $argv
end