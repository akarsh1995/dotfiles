# Function to initialize the password store
function pwstore_init
    # Define paths for password store
    set -l store_path $XDG_CONFIG_HOME/fish/secure/passwords
    
    # Create directory if it doesn't exist
    mkdir -p $store_path
    
    echo "Password store initialized at: $store_path"
    echo ""
    echo "Available commands:"
    echo "  pwstore_add NAME PASSWORD [DESCRIPTION]    - Add or update a password"
    echo "  pwstore_add --generate NAME [LENGTH] [DESC]- Generate and store a password"
    echo "  pwstore_get NAME [--copy|--show]           - Retrieve a password"
    echo "  pwstore_list [--details]                   - List all stored passwords"
    echo "  pwstore_delete NAME [--force]              - Delete a password"
    echo "  pwstore_export PATH                        - Export passwords to a file"
    echo "  pwstore_import PATH [--merge|--overwrite]  - Import passwords from a file"
end
