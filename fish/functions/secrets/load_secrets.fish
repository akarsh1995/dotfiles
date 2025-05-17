# Function to load all secrets from the encrypted JSON file
function load_secrets
    set -l encrypted_json_path $XDG_CONFIG_HOME/fish/conf.d/secrets.json.gpg
    
    if test ! -f $encrypted_json_path
        echo "No encrypted secrets file found. Use add_secret to create one."
        return 1
    end
    
    # Decrypt the secrets file directly to memory (using command substitution)
    set -l decrypted_content (gpg --quiet --decrypt $encrypted_json_path 2>/dev/null)
    if test $status -ne 0
        echo "Failed to decrypt secrets file"
        return 1
    end
    
    # Load each secret as an environment variable
    for key in (echo $decrypted_content | jq -r 'keys[]')
        set -l value (echo $decrypted_content | jq -r --arg key "$key" '.[$key].value')
        set -gx $key $value
    end
    
    # No need to clean up as we never wrote to disk
    
    echo "Secrets loaded successfully"
end
