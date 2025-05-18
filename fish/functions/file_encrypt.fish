# a function that encrypts a file and stores it in the encrypted registry
function file_encrypt
    # Define paths for encrypted files registry
    set -l registry_path $XDG_CONFIG_HOME/fish/secure/files/registry.json.gpg
    
    # check if the first argument is empty (source file)
    if test -z "$argv[1]"
        echo "Please provide a source file path"
        return 1
    end

    # check if the source file exists
    if test ! -f "$argv[1]"
        echo "Source file does not exist: $argv[1]"
        return 1
    end
    
    # Get file content as base64 encoded string to store in JSON
    set -l file_content (base64 -i "$argv[1]" | string collect)
    
    # Prepare registry JSON content
    set -l json_content "{}"
    
    # If we have an existing registry file, decrypt it to memory
    if test -f $registry_path
        set json_content (gpg --quiet --decrypt $registry_path 2>/dev/null)
        if test $status -ne 0
            echo "Failed to decrypt registry file"
            return 1
        end
    end
    
    # Get description if provided, otherwise use a default
    set -l description "Encrypted file"
    if test (count $argv) -ge 2 -a ! -z "$argv[2]"
        set description "$argv[2]"
    end
    
    # Get absolute path for reliable storage
    set -l abs_source_path (realpath "$argv[1]")
    
    # Get file modification time for versioning
    set -l modified_time (stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$argv[1]")
    
    # Update the JSON registry with the new encrypted file info and content
    echo $json_content | jq --arg source "$abs_source_path" --arg content "$file_content" \
       --arg desc "$description" --arg mtime "$modified_time" \
       '.[$source] = {"content": $content, "description": $desc, "modified_time": $mtime}' | \
       gpg --quiet --yes --recipient "Akarsh Jain" --encrypt --output $registry_path
    
    if test $status -ne 0
        echo "Failed to update encrypted files registry"
        return 1
    end
    
    echo "File encrypted successfully and stored in registry"
    echo "Original file path: $abs_source_path"
    
    # Check if --remove flag was used or ask the user about removing the original file
    set -l remove_file false
    
    for arg in $argv
        if test "$arg" = "--remove"
            set remove_file true
            break
        end
    end
    
    if not $remove_file
        read -l -P "Remove original file '$argv[1]'? [y/N] " confirm
        if string match -qi "y" $confirm
            set remove_file true
        end
    end
    
    # Securely remove the original file if requested
    if $remove_file
        # Check if shred command exists
        if command -sq shred
            # Use shred to securely delete the file (-u removes the file after overwriting)
            shred -u -z "$argv[1]"
            if test $status -eq 0
                echo "Original file securely shredded."
            else
                echo "Warning: Failed to securely shred original file."
            end
        else
            # If shred doesn't exist, use rm but warn the user
            echo "Warning: 'shred' command not found. Using standard rm which is less secure."
            rm "$argv[1]"
            if test $status -eq 0
                echo "Original file removed (not securely shredded)."
            else
                echo "Warning: Failed to remove original file."
            end
        end
    end
end
