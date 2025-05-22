# Completion for secret_edit function

# Register completion for secret_edit command - allows completing existing secret names
if functions -q __fish_complete_secrets
    complete -c secret_edit -f -a "(__fish_complete_secrets)" -d "Edit a secret value in a text editor"
else
    # Create the completion function if it doesn't exist
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
    
    complete -c secret_edit -f -a "(__fish_complete_secrets)" -d "Edit a secret value in a text editor"
end
