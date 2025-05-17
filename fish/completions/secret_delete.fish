# Completion for secret_delete function

function __fish_complete_secrets
    # Decrypt secrets directly to memory and extract keys (secret names)
    set -l encrypted_json_path $XDG_CONFIG_HOME/fish/secure/secrets/secrets.json.gpg
    
    if test -f $encrypted_json_path
        # Get the list of secret names
        set -l decrypted_content (gpg --quiet --decrypt $encrypted_json_path 2>/dev/null)
        if test $status -eq 0
            # Extract and output the keys
            echo $decrypted_content | jq -r 'keys[]'
        end
    end
end

# Register completion for secret_delete command
complete -c secret_delete -f -a "(__fish_complete_secrets)" -d "Stored secret"
