function opencode-move-project --description "Remap opencode sessions after renaming/moving a project directory"
    set -l args
    for arg in $argv
        set args $args $arg
    end
    if test (count $args) -lt 2
        echo "Usage: opencode-move-project [--dry-run] OLD_DIR NEW_DIR"
        return 1
    end
    python3 ~/.config/fish/scripts/opencode-move-project.py $argv
end
