# Function to backup all GPG keys in a zip file
function gpg_backup
    # Parse arguments
    set -l backup_dir ""
    set -l backup_name ""
    set -l include_trust true
    set -l help false
    
    # Parse command line arguments
    for i in (seq (count $argv))
        switch $argv[$i]
            case "--dir" "-d"
                if test (count $argv) -gt $i
                    set backup_dir $argv[(math $i + 1)]
                end
            case "--name" "-n"
                if test (count $argv) -gt $i
                    set backup_name $argv[(math $i + 1)]
                end
            case "--include-trust" "-t"
                set include_trust true
            case "--no-trust"
                set include_trust false
            case "--help" "-h"
                set help true
            case "--"
                break
        end
    end
    
    # Show help if requested
    if $help
        echo "Usage: gpg_backup [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  -d, --dir DIR        Directory to save backup (default: ~/Documents/gpg-backups)"
        echo "  -n, --name NAME      Custom backup name (default: gpg-backup-YYYY-MM-DD)"
        echo "      --no-trust       Skip trust database backup"
        echo "  -h, --help          Show this help message"
        echo ""
        echo "This function creates a password-protected zip file containing:"
        echo "  - All public keys (public-keys.asc)"
        echo "  - All private keys (private-keys.asc)"
        echo "  - Owner trust database (ownertrust.txt, default: included)"
        echo ""
        echo "The backup will be encrypted with a password you provide."
        return 0
    end
    
    # Set default backup directory
    if test -z "$backup_dir"
        set backup_dir "$HOME/Documents/gpg-backups"
    end
    
    # Set default backup name with current date
    if test -z "$backup_name"
        set backup_name "gpg-backup-"(date +%Y-%m-%d)
    end
    
    # Create backup directory if it doesn't exist
    mkdir -p "$backup_dir"
    
    # Create temporary directory for GPG exports
    set -l temp_dir (mktemp -d)
    
    echo "Creating GPG backup..."
    echo "Backup directory: $backup_dir"
    echo "Backup name: $backup_name"
    echo ""
    
    # Check if GPG is available
    if not command -sq gpg
        echo "Error: GPG is not installed or not in PATH"
        rm -rf "$temp_dir"
        return 1
    end
    
    # Check if there are any keys to backup
    set -l key_count (gpg --list-keys --with-colons | grep "^pub:" | wc -l | string trim)
    if test "$key_count" -eq 0
        echo "No GPG keys found to backup"
        rm -rf "$temp_dir"
        return 1
    end
    
    echo "Found $key_count GPG key(s) to backup"
    echo ""
    
    # Export all public keys
    echo "Exporting public keys..."
    gpg --armor --export > "$temp_dir/public-keys.asc"
    if test $status -ne 0
        echo "Error: Failed to export public keys"
        rm -rf "$temp_dir"
        return 1
    end
    
    # Export all private keys
    echo "Exporting private keys..."
    gpg --armor --export-secret-keys > "$temp_dir/private-keys.asc"
    if test $status -ne 0
        echo "Error: Failed to export private keys"
        rm -rf "$temp_dir"
        return 1
    end
    
    # Export trust database (now default)
    if $include_trust
        echo "Exporting trust database..."
        gpg --export-ownertrust > "$temp_dir/ownertrust.txt"
        if test $status -ne 0
            echo "Warning: Failed to export trust database"
        end
    else
        echo "Skipping trust database (--no-trust specified)..."
    end
    
    # Create a README file with instructions
    echo "Creating backup documentation..."
    set -l readme_content "GPG Keys Backup
Created: "(date)"
System: "(uname -a)"

This backup contains:
- public-keys.asc: All public keys
- private-keys.asc: All private keys"
    
    if $include_trust
        set readme_content "$readme_content
- ownertrust.txt: Trust database"
    else
        set readme_content "$readme_content
(Trust database was skipped with --no-trust)"
    end
    
    set readme_content "$readme_content

To restore these keys:

1. Import public keys:
   gpg --import public-keys.asc

2. Import private keys:
   gpg --import private-keys.asc"
    
    if $include_trust
        set readme_content "$readme_content

3. Import trust database:
   gpg --import-ownertrust ownertrust.txt"
    end
    
    echo "$readme_content" > "$temp_dir/README.txt"
    
    # Create the backup zip file
    set -l backup_file "$backup_dir/$backup_name.zip"
    
    echo ""
    echo "Creating encrypted zip file..."
    echo "You will be prompted to set a password for the backup."
    
    # Check if zip command supports encryption
    if command -sq zip
        # Change to temp directory to avoid full paths in zip
        pushd "$temp_dir"
        zip -e "$backup_file" *.asc *.txt 2>/dev/null
        set -l zip_status $status
        popd
        
        if test $zip_status -ne 0
            echo "Error: Failed to create encrypted zip file"
            rm -rf "$temp_dir"
            return 1
        end
    else
        echo "Error: zip command not found"
        rm -rf "$temp_dir"
        return 1
    end
    
    # Clean up temporary directory
    rm -rf "$temp_dir"
    
    # Get file size for reporting
    set -l file_size (du -h "$backup_file" | cut -f1)
    
    echo ""
    echo "✅ GPG backup created successfully!"
    echo "📁 Location: $backup_file"
    echo "📊 Size: $file_size"
    echo ""
    echo "⚠️  Important security notes:"
    echo "   - Store this backup in a secure location"
    echo "   - Remember the password you just set"
    echo "   - Consider storing the password separately"
    echo "   - This backup contains your private keys"
    echo ""
    echo "To restore from this backup:"
    echo "   1. Unzip the file: unzip $backup_name.zip"
    echo "   2. Follow instructions in README.txt"
end
