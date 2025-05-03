if status is-interactive
    # Commands to run in interactive sessions can go here
    eval "$(/opt/homebrew/bin/brew shellenv)"
    source (/opt/homebrew/bin/starship init fish --print-full-init | psub)
    zoxide init fish | source
end
