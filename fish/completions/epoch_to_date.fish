# Completions for epoch_to_date function

complete -c epoch_to_date -f -d "Convert epoch timestamp to human readable datetime"

# Common date format examples
complete -c epoch_to_date -n "test (count (commandline -opc)) -eq 3" -a "'%Y-%m-%d %H:%M:%S'" -d "YYYY-MM-DD HH:MM:SS"
complete -c epoch_to_date -n "test (count (commandline -opc)) -eq 3" -a "'%Y-%m-%d'" -d "YYYY-MM-DD"
complete -c epoch_to_date -n "test (count (commandline -opc)) -eq 3" -a "'%H:%M:%S'" -d "HH:MM:SS"
complete -c epoch_to_date -n "test (count (commandline -opc)) -eq 3" -a "'%c'" -d "Complete date and time"
complete -c epoch_to_date -n "test (count (commandline -opc)) -eq 3" -a "'%Y-%m-%d %H:%M:%S %Z'" -d "YYYY-MM-DD HH:MM:SS TZ (default)"
complete -c epoch_to_date -n "test (count (commandline -opc)) -eq 3" -a "'%Y-%m-%dT%H:%M:%S%z'" -d "ISO 8601 format"
complete -c epoch_to_date -n "test (count (commandline -opc)) -eq 3" -a "'%A, %B %d, %Y'" -d "Day, Month DD, YYYY"
complete -c epoch_to_date -n "test (count (commandline -opc)) -eq 3" -a "'%b %d %H:%M'" -d "Mon DD HH:MM"
