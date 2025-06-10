# Completions for gpg_backup function

complete -c gpg_backup -f -d "Backup all GPG keys in a zip file"

# Options
complete -c gpg_backup -s d -l dir -d "Directory to save backup" -r -a "(__fish_complete_directories)"
complete -c gpg_backup -s n -l name -d "Custom backup name" -r
complete -c gpg_backup -l no-trust -d "Skip trust database backup"
complete -c gpg_backup -s h -l help -d "Show help message"
