if status is-interactive
    # Load secrets from the encrypted JSON file
    if type -q load_secrets
        load_secrets
    end
    generate_docker_aliases $AYR_DIR/integration/docker-compose.yml be-lite
    fzf_configure_bindings --directory=\cf --variables=\e\cv
end
