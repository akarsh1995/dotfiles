# Completion for export_as_secret function

# Function to list all available environment variables
function __fish_complete_env_vars
    set -ng | sed 's/=.*//' | sort
end

# Register completion for export_as_secret command
complete -c export_as_secret -f -a "(__fish_complete_env_vars)" -d "Environment variable to export"
