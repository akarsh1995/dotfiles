function generate_docker_aliases
    # Check for correct arguments
    if test (count $argv) -lt 1 -o (count $argv) -gt 2
        echo "Usage: generate_docker_aliases <compose_file> [profile]"
        return 1
    end

    set -l compose_file $argv[1]
    set -l profile_arg ""

    # Check if profile is provided
    if test (count $argv) -eq 2
        set profile_arg "--profile="$argv[2]
    end

    # Check if the provided compose file exists
    if not test -f $compose_file
        echo "Error: $compose_file not found."
        return 1
    end

    # Extract service names from the provided docker-compose file, with optional profile
    set -l services (docker-compose -f $compose_file $profile_arg config --services)

    # Generate aliases for each service
    for service in $services
        alias "dc-$service" "docker-compose -f $compose_file up $service"
        alias "dc-$service-build" "docker-compose -f $compose_file up --build $service"
    end
end
