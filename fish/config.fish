if status is-interactive
    generate_docker_aliases $AYR_DIR/integration/docker-compose.yml be-lite
    alias eu-bhishma "docker compose -f $AYR_DIR/integration/docker-compose.yml --profile=be-lite up -d"
    alias eu-fe "docker compose -f $AYR_DIR/integration/docker-compose.yml --profile=fe up -d"
    alias ed "docker-compose -f $AYR_DIR/integration/docker-compose.yml --profile=be-lite down --remove-orphans"
    fzf_configure_bindings --directory=\cf --variables=\e\cv
    nvm use v20.13.1
end
