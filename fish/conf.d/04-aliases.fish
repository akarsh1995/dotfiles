alias ghcs 'gh copilot suggest -t shell'
alias open_recent_pr 'gh pr list --state open --author "@me" --json number | jq -r ".[0].number" | xargs gh pr view --web'
alias gp 'git push origin HEAD'
alias open_repo 'gh repo view --web'

# user defined aliases that are dependent on environment variables
function credit_test_user
    npm run setup:user -- --walletAddress=$LOCAL_TEST_USER --token=USDCBC --amountInHr=10000 $argv
end

function eu-bhishma
    docker compose -f $AYR_DIR/integration/docker-compose.yml --profile=be-lite up -d $argv
end

function ed
    docker-compose -f $AYR_DIR/integration/docker-compose.yml --profile=be-lite down --remove-orphans $argv
end

function eu-fe
    docker compose -f $AYR_DIR/integration/docker-compose.yml --profile=fe up -d $argv
    credit_test_user
end

function ed-fe
    docker-compose -f $AYR_DIR/integration/docker-compose.yml --profile=fe down --remove-orphans $argv
end

function telu
    docker-compose -f $AYR_DIR/telemetry/docker-compose.telemetry.yml up -d --build $argv
end

function teld
    docker-compose -f $AYR_DIR/telemetry/docker-compose.telemetry.yml down $argv
end
