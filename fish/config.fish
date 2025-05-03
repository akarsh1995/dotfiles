if status is-interactive
    generate_docker_aliases $AYR_DIR/integration/docker-compose.yml
    alias eu-bhishma "docker-compose -f $AYR_DIR/integration/docker-compose.yml up"
    fzf_configure_bindings --directory=\cf --variables=\e\cv
end
