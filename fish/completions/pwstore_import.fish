# Completions for pwstore_import function
complete -c pwstore_import -f -d "Import passwords from a GPG-encrypted backup file"
complete -c pwstore_import -a "(__fish_complete_path)" -d "Import file path"
complete -c pwstore_import -l merge -d "Combine with existing passwords (default)"
complete -c pwstore_import -l overwrite -d "Replace all existing passwords"
