# Completions for psql_json function

complete -c psql_json -f -d "Execute PostgreSQL table queries and return JSON results"

# Function to get table names from the database
function __psql_json_get_tables
    # Extract connection string from command line
    set -l connection_string ""
    set -l cmd (commandline -opc)

    # Look for connection string in current command
    for i in (seq (count $cmd))
        if test "$cmd[$i]" = -c; or test "$cmd[$i]" = --connection
            set j (math $i + 1)
            if test $j -le (count $cmd)
                set -l raw_connection $cmd[$j]

                # Check if it's a command substitution and evaluate it
                if string match -q "(*)" -- "$raw_connection"
                    # Extract the command inside parentheses and evaluate it
                    set -l inner_cmd (string sub -s 2 -e -1 "$raw_connection")
                    # Evaluate the command in a subshell to avoid polluting current environment
                    set connection_string (eval $inner_cmd 2>/dev/null)
                else
                    set connection_string $raw_connection
                end
                break
            end
        end
    end

    # If no connection string in command line, try environment variables
    if test -z "$connection_string"
        if set -q PSQL_CONNECTION
            set connection_string $PSQL_CONNECTION
        else if set -q DATABASE_URL
            set connection_string $DATABASE_URL
        end
    end

    # If we have a connection string, query for tables
    if test -n "$connection_string"; and command -sq psql
        # Query to get table names from information_schema
        set -l tables_query "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;"

        # Execute query and return table names (suppress errors)
        psql -t "$connection_string" -c "$tables_query" 2>/dev/null | string trim | string match -v ""
    end
end

# Function to get column names for a specific table
function __psql_json_get_columns
    # Extract connection string and table name from command line
    set -l connection_string ""
    set -l table_name ""
    set -l cmd (commandline -opc)

    # Look for connection string and table name in current command
    for i in (seq (count $cmd))
        if test "$cmd[$i]" = -c; or test "$cmd[$i]" = --connection
            set j (math $i + 1)
            if test $j -le (count $cmd)
                set -l raw_connection $cmd[$j]

                # Check if it's a command substitution and evaluate it
                if string match -q "(*)" -- "$raw_connection"
                    # Extract the command inside parentheses and evaluate it
                    set -l inner_cmd (string sub -s 2 -e -1 "$raw_connection")
                    set connection_string (eval $inner_cmd 2>/dev/null)
                else
                    set connection_string $raw_connection
                end
            end
        else if test "$cmd[$i]" = -t; or test "$cmd[$i]" = --table
            set j (math $i + 1)
            if test $j -le (count $cmd)
                set table_name $cmd[$j]
            end
        end
    end

    # If no table specified with -t, look for positional table argument
    if test -z "$table_name"
        # Find the first argument that's not a flag or flag value
        set -l skip_next false
        for i in (seq 2 (count $cmd)) # Start from 2 to skip command name
            if $skip_next
                set skip_next false
                continue
            end
            
            set -l arg $cmd[$i]
            if string match -q -- "-*" $arg
                # This is a flag, check if it takes a value
                if test "$arg" = -c; or test "$arg" = --connection; or test "$arg" = -t; or test "$arg" = --table; or test "$arg" = -w; or test "$arg" = --where
                    set skip_next true
                end
                continue
            end
            
            # This looks like a positional argument (table name)
            set table_name $arg
            break
        end
    end

    # If no connection string in command line, try environment variables
    if test -z "$connection_string"
        if set -q PSQL_CONNECTION
            set connection_string $PSQL_CONNECTION
        else if set -q DATABASE_URL
            set connection_string $DATABASE_URL
        end
    end

    # If we have both connection string and table name, query for columns
    if test -n "$connection_string"; and test -n "$table_name"; and command -sq psql
        # Query to get column names from information_schema
        set -l columns_query "SELECT column_name FROM information_schema.columns WHERE table_name = '$table_name' AND table_schema = 'public' ORDER BY ordinal_position;"

        # Execute query and return column names (suppress errors)
        psql -t "$connection_string" -c "$columns_query" 2>/dev/null | string trim | string match -v ""
    end
end

# Options
complete -c psql_json -s c -l connection -d "Database connection string" -r
complete -c psql_json -s t -l table -d "Table name to query" -r -f -a "(__psql_json_get_tables)"
complete -c psql_json -s w -l where -d "WHERE clause for table queries" -r -f -a "(__psql_json_get_columns)"
complete -c psql_json -l tsv -d "Output as TSV for spreadsheets"
complete -c psql_json -s h -l help -d "Show help message"

# Column name completion for WHERE clause arguments
complete -c psql_json -n "__fish_seen_subcommand_from -w --where" -f -a "(__psql_json_get_columns)" -d "Column name"

# Common connection string examples
complete -c psql_json -n "__fish_seen_subcommand_from -c --connection" -a "'postgres://user:password@localhost:5432/database'" -d "Connection string template"
complete -c psql_json -n "__fish_seen_subcommand_from -c --connection" -a "'postgres://postgres:postgres@localhost:5432/postgres'" -d "Default PostgreSQL connection"

# Table name completion for positional argument (when no -t flag is used)
complete -c psql_json -n "not __fish_seen_subcommand_from -t --table -c --connection -w --where --tsv -h --help" -a "(__psql_json_get_tables)" -d "Table name"
