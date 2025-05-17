# Function to delete a secret
function secret_delete
    # Define paths for secrets
    set -l encrypted_json_path $XDG_CONFIG_HOME/fish/conf.d/secrets.json.gpg
    
    # check if the first argument is empty
    if test -z "$argv[1]"
        echo "Please provide the secret name to delete"
        return 1
    end

    # Check if the encrypted file exists
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
    
    # Check if the secret exists
    if not echo $decrypted_content | jq -e --arg key "$argv[1]" 'has($key)' > /dev/null
        echo "Secret '$argv[1]' does not exist"
        return 1
    end
    
    # Delete the secret and encrypt directly from memory to file
    echo $decrypted_content | jq --arg key "$argv[1]" 'del(.[$key])' | \
       gpg --quiet --yes --recipient "Akarsh Jain" --encrypt --output $encrypted_json_path
    
    if test $status -ne 0
        echo "Failed to encrypt secrets file"
        return 1
    end
    
    # Remove the variable from the environment
    set -e $argv[1]
    
    echo "Secret '$argv[1]' deleted successfully"
end
