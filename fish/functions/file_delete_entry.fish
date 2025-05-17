# Function to delete an entry from the encrypted files registry
function file_delete_entry
    # Define paths for encrypted files registry
    set -l registry_path $XDG_CONFIG_HOME/fish/secure/files/registry.json.gpg
    
    # check if the first argument is empty (original file path)
    if test -z "$argv[1]"
        echo "Please provide the original file path to delete from registry"
        return 1
    end
    
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
    
    # Get absolute path for reliable lookup
    set -l abs_source_path (realpath "$argv[1]" 2>/dev/null || echo "$argv[1]")
    
    # Check if the file exists in registry
    if not echo $decrypted_content | jq -e --arg source "$abs_source_path" 'has($source)' > /dev/null
        echo "No entry found for: $abs_source_path"
        return 1
    end
    
    # Get description for reporting
    set -l description (echo $decrypted_content | jq -r --arg source "$abs_source_path" '.[$source].description')
    
    # Ask for confirmation if --force flag is not provided
    set -l force false
    for arg in $argv
        if test "$arg" = "--force"
            set force true
            break
        end
    end
    
    if not $force
        read -l -P "Delete entry for '$abs_source_path' ($description)? [y/N] " confirm
        if not string match -qi "y" $confirm
            echo "Operation cancelled."
            return 0
        end
    end
    
    # Remove the entry from the registry
    echo $decrypted_content | jq --arg source "$abs_source_path" 'del(.[$source])' | \
        gpg --quiet --yes --recipient "Akarsh Jain" --encrypt --output $registry_path
    
    if test $status -ne 0
        echo "Failed to update registry file"
        return 1
    end
    
    echo "Registry entry deleted successfully."
end
