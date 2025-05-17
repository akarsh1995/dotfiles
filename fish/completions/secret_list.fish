# Completion for secret_list function

# Add completion for secret_list options
complete -c secret_list -f -d "List all available secrets"
complete -c secret_list -l with-masked-values -f -d "Show masked values for secrets"
