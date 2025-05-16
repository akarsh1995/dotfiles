# Function to list all available secrets without showing their values
function list_secrets
    set -l encrypted_json_path $XDG_CONFIG_HOME/fish/conf.d/secrets.json.gpg
    
    if test ! -f $encrypted_json_path
        echo "No encrypted secrets file found."
        return 1
    end
    
    # Decrypt the secrets file directly to memory (using command substitution)
    set -l decrypted_content (gpg --quiet --decrypt $encrypted_json_path 2>/dev/null)
    if test $status -ne 0
        echo "Failed to decrypt secrets file"
        return 1
    end
    
    # Create a formatted list of secrets and their descriptions
    echo "Available Secrets:"
    echo "--------------------------------------------------------------------------------"
    echo $decrypted_content | jq -r 'to_entries | .[] | "\(.key) - \(.value.description)"' | sort
    
    # No need to clean up as we never wrote to disk
end
