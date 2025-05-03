function generate_docker_aliases
    # Ensure the compose file is provided as an argument
    if test (count $argv) -ne 1
        echo "Usage: generate_docker_aliases <compose_file>"
        return 1
    end

    set -l compose_file $argv[1]

    # Check if the provided compose file exists
    if not test -f $compose_file
        echo "Error: $compose_file not found."
        return 1
    end

    # Extract service names from the provided docker-compose file
    set -l services (docker-compose -f $compose_file config --services)

    # Generate aliases for each service
    for service in $services
        alias "dc-$service" "docker-compose -f $compose_file up $service"
        alias "dc-$service-build" "docker-compose -f $compose_file up --build $service"
    end
end
