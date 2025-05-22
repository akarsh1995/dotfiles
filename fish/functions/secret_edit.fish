# Function to edit a secret using a text editor
function secret_edit
    # Define paths for secrets
    set -l encrypted_json_path $XDG_CONFIG_HOME/fish/secure/secrets/secrets.json.gpg
    
    # check if the first argument is empty
    if test -z "$argv[1]"
        echo "Please provide the secret name to edit"
        return 1
    end
    
    # Check if the encrypted file exists
    if test ! -f $encrypted_json_path
        echo "No encrypted secrets file found."
        return 1
    end
    
    # Decrypt the secrets file directly to memory
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
    
    # Get the current value and description
    set -l current_value (echo $decrypted_content | jq -r --arg key "$argv[1]" '.[$key].value')
    set -l current_description (echo $decrypted_content | jq -r --arg key "$argv[1]" '.[$key].description')
    
    # Create a temporary file with the secret content
    set -l temp_file (mktemp)
    
    # Add a comment at the top explaining the file and instructions
    echo "# Editing secret: $argv[1]" > $temp_file
    echo "# Description: $current_description" >> $temp_file
    echo "# " >> $temp_file
    echo "# Lines starting with # will be ignored." >> $temp_file
    echo "# Save and exit the editor to update the secret." >> $temp_file
    echo "# To cancel, delete all content and save an empty file." >> $temp_file
    echo "# " >> $temp_file
    echo "$current_value" >> $temp_file
    
    # Open the file in the default editor
    set -l editor $EDITOR
    if test -z "$editor"
        set editor "vim"
    end
    
    $editor $temp_file
    
    # Check if editing was successful
    if test $status -ne 0
        echo "Editor exited with an error"
        rm -f $temp_file
        return 1
    end
    
    # Read the edited content, filtering out comment lines
    set -l new_content (grep -v "^#" $temp_file | string collect)
    
    # Check if the file is empty (which means cancel the operation)
    if test -z "$new_content"
        echo "Edit cancelled - no changes made"
        rm -f $temp_file
        return 0
    end
    
    # Update the JSON with the new secret and encrypt directly from memory to file
    echo $decrypted_content | jq --arg key "$argv[1]" --arg value "$new_content" --arg desc "$current_description" \
       '.[$key] = {"value": $value, "description": $desc}' | \
       gpg --quiet --yes --recipient "Akarsh Jain" --encrypt --output $encrypted_json_path
    
    if test $status -ne 0
        echo "Failed to encrypt secrets file"
        rm -f $temp_file
        return 1
    end
    
    # Check if the secret was updated successfully
    set -l verification_content (gpg --quiet --decrypt $encrypted_json_path 2>/dev/null)
    if not echo $verification_content | jq -e --arg key "$argv[1]" 'has($key)' > /dev/null
        echo "Failed to update secret"
        rm -f $temp_file
        return 1
    end
    
    # Verify the new content
    set -l verification_value (echo $verification_content | jq -r --arg key "$argv[1]" '.[$key].value')
    if test "$verification_value" != "$new_content"
        echo "Verification failed - content mismatch"
        rm -f $temp_file
        return 1
    end
    
    # Clean up the temporary file
    rm -f $temp_file
    
    # Update the variable in the current environment
    set -gx $argv[1] $new_content
    
    echo "Secret '$argv[1]' updated successfully"
end
