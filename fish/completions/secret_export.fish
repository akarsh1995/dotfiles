# Completion for secret_export function

# Function to list all available environment variables
function __fish_complete_env_vars
    set -ng | sed 's/=.*//' | sort
end

# Register completion for secret_export command
complete -c secret_export -f -a "(__fish_complete_env_vars)" -d "Environment variable to export"
