# Add secrets directory to function path for Fish to find the functions
if test -d $XDG_CONFIG_HOME/fish/functions/secrets
    # Add the secrets directory to the fish function path
    if not contains $XDG_CONFIG_HOME/fish/functions/secrets $fish_function_path
        set -gx fish_function_path $fish_function_path $XDG_CONFIG_HOME/fish/functions/secrets
    end
end
