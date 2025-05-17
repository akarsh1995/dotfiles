# Completions for file_restore_all function
complete -c file_restore_all -f -d "Restore multiple or all encrypted files"
complete -c file_restore_all -l pattern -d "Only restore files matching the glob pattern" -r
complete -c file_restore_all -l output-dir -d "Restore all files to this directory, preserving relative paths" -r -a "(__fish_complete_directories)"
complete -c file_restore_all -l help -d "Display help message"
