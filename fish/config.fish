if status is-interactive
    generate_docker_aliases $AYR_DIR/integration/docker-compose.yml be-lite
    fzf_configure_bindings --directory=\cf --variables=\e\cv
end
