if status is-interactive
    fzf_configure_bindings --directory=\cf --variables=\e\cv
    fish_add_path -g $HOME/.local/bin
    set -x PSQL_CONNECTION (echo $DBEE_CONNECTIONS | jq -r ".[0].url")
    alias sync_private_fork "git fetch upstream && git rebase upstream/main"
end

# Added by Antigravity
fish_add_path $HOME/.antigravity/antigravity/bin
fish_add_path $HOME/Programming/sms-notifier/python
fish_add_path $HOME/sessionmanager-bundle/sessionmanager-bundle/bin
alias request_totp "sms_listener.py request"
alias request_totp_aws "request_totp aws"

# Added by codebase-memory-mcp install
export PATH="/Users/akarshjain/.local/bin:$PATH"
