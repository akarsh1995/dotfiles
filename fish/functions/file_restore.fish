# a function that restores an encrypted file from the registry
function file_restore
    # Define paths for encrypted files registry
    set -l registry_path $XDG_CONFIG_HOME/fish/secure/files/registry.json.gpg
    
    # Check if registry exists
    if test ! -f $registry_path
        echo "No encrypted files registry found."
        return 1
    end
    
    # Decrypt the registry directly to memory
    set -l decrypted_content (gpg --quiet --decrypt $registry_path 2>/dev/null)
    if test $status -ne 0
        echo "Failed to decrypt registry file"
        return 1
    end
    
    # check if the first argument is empty (original file path)
    if test -z "$argv[1]"
        echo "Please provide the original file path to restore"
        return 1
    end
    
    # Get absolute path for reliable lookup
    set -l abs_source_path (realpath "$argv[1]" 2>/dev/null || echo "$argv[1]")
    
    # Check if the file exists in registry
    if not echo $decrypted_content | jq -e --arg source "$abs_source_path" 'has($source)' > /dev/null
        echo "No entry found for: $abs_source_path"
        return 1
    end
    
    # Get the file content from the registry
    set -l file_content (echo $decrypted_content | jq -r --arg source "$abs_source_path" '.[$source].content')
    set -l modified_time (echo $decrypted_content | jq -r --arg source "$abs_source_path" '.[$source].modified_time')
    
    # Set the destination path
    set -l dest_path "$abs_source_path"
    set -l custom_destination false
    
    if test (count $argv) -ge 2 -a ! -z "$argv[2]"
        set dest_path "$argv[2]"
        set custom_destination true
    end
    
    # Create directory structure if it doesn't exist
    set -l dir_path (dirname "$dest_path")
    mkdir -p "$dir_path"
    
    # Decode base64 content and write to file
    echo $file_content | base64 -d > "$dest_path"
    
    if test $status -ne 0
        echo "Failed to restore file"
        return 1
    end
    
    # Try to set the original modification time
    if test ! -z "$modified_time"
        touch -d "$modified_time" "$dest_path" 2>/dev/null
        # If touch -d fails (e.g., on macOS), try alternative format
        if test $status -ne 0
            touch -t (echo $modified_time | string replace -a "-" "" | string replace -a ":" "" | string replace " " "") "$dest_path" 2>/dev/null
        end
    end
    
    if $custom_destination
        echo "File restored successfully to custom location: $dest_path"
        echo "Original file path: $abs_source_path"
    else
        echo "File restored successfully to original path: $dest_path"
    end
    
    if test ! -z "$modified_time"
        echo "Original modified time: $modified_time"
    end
end
