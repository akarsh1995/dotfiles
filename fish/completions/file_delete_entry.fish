# Completions for file_delete_entry function
function __file_delete_entry_candidates
    set -l registry_path $XDG_CONFIG_HOME/fish/secure/files/registry.json.gpg
    if test -f $registry_path
        gpg --quiet --decrypt $registry_path 2>/dev/null | jq -r 'keys[]'
    end
end

complete -c file_delete_entry -f -d "Delete an entry from encrypted files registry"
complete -c file_delete_entry -a "(__file_delete_entry_candidates)"
complete -c file_delete_entry -l force -d "Delete without confirmation"
