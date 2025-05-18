# Completions for file_encrypt function
complete -c file_encrypt -f -d "Encrypt a file and add to registry"
complete -c file_encrypt -a "(find . -type f -not -path '*/\.git/*')"
complete -c file_encrypt -l remove -d "Remove the original file after encryption without prompting"
