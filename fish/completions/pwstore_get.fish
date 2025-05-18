# Completions for pwstore_get function
function __pwstore_get_candidates
    set -l registry_path $XDG_CONFIG_HOME/fish/secure/passwords/registry.json.gpg
    if test -f $registry_path
        gpg --quiet --decrypt $registry_path 2>/dev/null | jq -r 'keys[]'
    end
end

complete -c pwstore_get -f -d "Retrieve a password from the password store"
complete -c pwstore_get -a "(__pwstore_get_candidates)"
complete -c pwstore_get -l copy -d "Copy password to clipboard (default)"
complete -c pwstore_get -l show -d "Show password in terminal"
