if status is-interactive
    generate_docker_aliases $AYR_DIR/integration/docker-compose.yml be-lite
    fzf_configure_bindings --directory=\cf --variables=\e\cv
    fish_add_path -g $HOME/.local/bin
end
