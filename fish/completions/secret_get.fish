# Completion for secret_get function

# Reuse the __fish_complete_secrets function if it exists
if not functions -q __fish_complete_secrets
    function __fish_complete_secrets
        # Decrypt secrets directly to memory and extract keys (secret names)
        set -l encrypted_json_path $XDG_CONFIG_HOME/fish/conf.d/secrets.json.gpg
        
        if test -f $encrypted_json_path
            # Get the list of secret names
            set -l decrypted_content (gpg --quiet --decrypt $encrypted_json_path 2>/dev/null)
            if test $status -eq 0
                # Extract and output the keys
                echo $decrypted_content | jq -r 'keys[]'
            end
        end
    end
end

# Register completion for secret_get command
complete -c secret_get -f -a "(__fish_complete_secrets)" -d "Stored secret"

# Add completion for secret_get options
complete -c secret_get -n "__fish_seen_subcommand_from (__fish_complete_secrets)" -l with-description -f -d "Show secret with description"
complete -c secret_get -n "__fish_seen_subcommand_from (__fish_complete_secrets)" -l with-name -f -d "Show secret with name"
complete -c secret_get -n "__fish_seen_subcommand_from (__fish_complete_secrets)" -l json -f -d "Output secret as JSON"
