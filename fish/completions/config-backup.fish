complete -c config-backup -f
complete -c config-backup -n '__fish_use_subcommand' -a status -d 'Show branch state and recent log'
complete -c config-backup -n '__fish_use_subcommand' -a log -d 'Tail the backup log'
complete -c config-backup -l dry-run -s n -d 'Preview without committing or pushing'
complete -c config-backup -l no-manifests -d 'Skip the brew/fisher manifest refresh'
complete -c config-backup -l help -s h -d 'Show usage'