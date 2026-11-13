function ai
    # Gather additional context to pass to the Python helper via AI_EXTRA_CONTEXT
    # Current working directory
    set -l cwd (pwd)
    # Git branch (if inside a repository)
    set -l git_branch ''
    if test -d .git
        set -l git_branch (git rev-parse --abbrev-ref HEAD ^/dev/null 2>/dev/null)
    end
    # Detect available package managers
    set -l pkg_mgrs ''
    for mgr in brew apt yum pacman dnf npm pip
        if type -q $mgr
            set pkg_mgrs $pkg_mgrs $mgr
        end
    end
    # Build a semicolon‑separated context string (only whitelisted env var LANG)
    set -gx AI_EXTRA_CONTEXT "cwd=$cwd;git_branch=$git_branch;pkg_mgrs=(string join ',' $pkg_mgrs);LANG=$LANG"

    # Run the AI helper with the natural‑language description you typed
    set -l generated (python3 /Users/akarshjain/Programming/cli-ai-tool/ai_helper.py $argv)
    if test -z "$generated"
        echo "❌  No command generated"
        return 1
    end
    # Replace the current command line with the generated command
    commandline -r "$generated"
    # Uncomment the next line to execute the command immediately after replacement
    # commandline -f execute
end
