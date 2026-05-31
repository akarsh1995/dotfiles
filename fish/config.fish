if status is-interactive
    fzf_configure_bindings --directory=\cf --variables=\e\cv
    fish_add_path -g $HOME/.local/bin
    set -x PSQL_CONNECTION (echo $DBEE_CONNECTIONS | jq -r ".[0].url")
    alias sync_private_fork "git fetch upstream && git rebase upstream/main"
end

# Added by Antigravity
fish_add_path $HOME/.antigravity/antigravity/bin
fish_add_path $HOME/sessionmanager-bundle/sessionmanager-bundle/bin

# SMS Notifier (Rust)
set -g SMSNOTIFIER_BIN $HOME/Programming/sms-notifier/smsnotifier

function smsnotifier-request
    if test (count $argv) -eq 0
        return 1
    end
    $SMSNOTIFIER_BIN request $argv[1]
end

function smsnotifier-logs
    tail -f ~/Library/Logs/smsnotifier.log
end

function smsnotifier-status
    if launchctl list | grep -q com.smsnotifier.listener
        echo "SMS Notifier is running"
        ps aux | grep smsnotifier | grep -v grep | head -1
    else
        echo "SMS Notifier is NOT running"
    end
end

alias sms-request smsnotifier-request
alias sms-logs smsnotifier-logs
alias sms-status smsnotifier-status

# Added by codebase-memory-mcp install
export PATH="/Users/akarshjain/.local/bin:$PATH"

# AI helper Tab completion – replace line when using `ai`
function __fish_ai_tab_replace --description "Replace ai command with generated output on Tab"
    # Get the full command line left of the cursor
    set -l line (commandline -b)
    if string match -qr '^ai\s' $line
        # Strip the leading "ai "
        set -l rest (string replace -r '^ai\s*' '' $line)
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
    # Call the helper, passing the natural language description
    set -l generated (python3 /Users/akarshjain/Programming/cli-ai-tool/ai_helper.py "$rest")
        # Replace the entire command line with the generated command
        commandline -r "$generated"
    else
        # Fallback to normal completion
        commandline -f complete
    end
end

# Bind Tab to the custom function (preserves normal completions for other commands)
bind \t __fish_ai_tab_replace
