alias ls 'nnn -de'
alias ghcs 'gh copilot suggest -t shell'
alias open_recent_pr 'gh pr list --state open --author "@me" --json number | jq -r ".[0].number" | xargs gh pr view --web'
