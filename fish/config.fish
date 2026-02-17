if status is-interactive
    generate_docker_aliases $AYR_DIR/integration/docker-compose.yml be-lite
    fzf_configure_bindings --directory=\cf --variables=\e\cv
    fish_add_path -g $HOME/.local/bin
    set -x PSQL_CONNECTION (echo $DBEE_CONNECTIONS | jq -r ".[0].url")
    alias sync_private_fork "git fetch upstream && git rebase upstream/main"
end
