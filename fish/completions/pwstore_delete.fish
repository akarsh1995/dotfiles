# Completions for pwstore_delete function
function __pwstore_delete_candidates
    set -l registry_path $XDG_CONFIG_HOME/fish/secure/passwords/registry.json.gpg
    if test -f $registry_path
        gpg --quiet --decrypt $registry_path 2>/dev/null | jq -r 'keys[]'
    end
end

complete -c pwstore_delete -f -d "Delete a password from the password store"
complete -c pwstore_delete -a "(__pwstore_delete_candidates)"
complete -c pwstore_delete -l force -d "Delete without confirmation"
