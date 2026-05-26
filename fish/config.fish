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
set -g SMSNOTIFIER_BIN $HOME/Programming/sms-notifier/rust/target/release/smsnotifier

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
