alias ghcs 'gh copilot suggest -t shell'
alias open_recent_pr 'gh pr list --state open --author "@me" --json number | jq -r ".[0].number" | xargs gh pr view --web'
alias gp 'git push origin HEAD'

# user defined aliases
alias eu-bhishma "docker compose -f $AYR_DIR/integration/docker-compose.yml --profile=be-lite up -d"
alias ed "docker-compose -f $AYR_DIR/integration/docker-compose.yml --profile=be-lite down --remove-orphans"
alias eu-fe "docker compose -f $AYR_DIR/integration/docker-compose.yml --profile=fe up -d"
alias ed-fe "docker-compose -f $AYR_DIR/integration/docker-compose.yml --profile=fe down --remove-orphans"
alias telu "docker-compose -f $AYR_DIR/telemetry/docker-compose.telemetry.yml up -d --build"
alias teld "docker-compose -f $AYR_DIR/telemetry/docker-compose.telemetry.yml down"