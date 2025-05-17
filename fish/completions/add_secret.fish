# Completion for add_secret function

# Reuse the __fish_complete_secrets function from delete_secret.fish if it exists
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

# Register completion for add_secret command - allows completing existing secret names for updating
complete -c add_secret -f -a "(__fish_complete_secrets)" -d "Update existing secret"
