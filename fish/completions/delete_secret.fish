# Completion for delete_secret function

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

# Register completion for delete_secret command
complete -c delete_secret -f -a "(__fish_complete_secrets)" -d "Stored secret"
