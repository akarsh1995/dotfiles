# Completions for file_restore function
function __file_restore_candidates
    set -l registry_path $XDG_CONFIG_HOME/fish/secure/files/registry.json.gpg
    if test -f $registry_path
        gpg --quiet --decrypt $registry_path 2>/dev/null | jq -r 'keys[]'
    end
end

complete -c file_restore -f -d "Restore an encrypted file"
complete -c file_restore -a "(__file_restore_candidates)" -n "test (count (commandline -opc)) -eq 2" -d "Original file path"
complete -c file_restore -F -n "test (count (commandline -opc)) -eq 3" -d "Custom destination path"
