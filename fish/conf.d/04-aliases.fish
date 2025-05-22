alias ghcs 'gh copilot suggest -t shell'
alias open_recent_pr 'gh pr list --state open --author "@me" --json number | jq -r ".[0].number" | xargs gh pr view --web'
alias gp 'git push origin HEAD'
alias open_repo 'gh repo view --web'
alias rm shred

# user defined aliases
alias credit_test_user "npm run setup:user -- --walletAddress=$LOCAL_TEST_USER --token=USDCBC --amountInHr=10000"
alias eu-bhishma "docker compose -f $AYR_DIR/integration/docker-compose.yml --profile=be-lite up -d"
alias ed "docker-compose -f $AYR_DIR/integration/docker-compose.yml --profile=be-lite down --remove-orphans"
alias eu-fe "docker compose -f $AYR_DIR/integration/docker-compose.yml --profile=fe up -d && credit_test_user"
alias ed-fe "docker-compose -f $AYR_DIR/integration/docker-compose.yml --profile=fe down --remove-orphans"
alias telu "docker-compose -f $AYR_DIR/telemetry/docker-compose.telemetry.yml up -d --build"
alias teld "docker-compose -f $AYR_DIR/telemetry/docker-compose.telemetry.yml down"
