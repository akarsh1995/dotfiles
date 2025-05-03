if status is-interactive
    generate_docker_aliases $AYR_DIR/integration/docker-compose.yml
    alias eu-bhishma "docker-compose -f $AYR_DIR/integration/docker-compose.yml up"
end
