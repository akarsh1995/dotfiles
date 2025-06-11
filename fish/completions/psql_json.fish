# Completions for psql_json function

complete -c psql_json -f -d "Execute PostgreSQL queries and return JSON results"

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

# Options
complete -c psql_json -s c -l connection -d "Database connection string" -r
complete -c psql_json -s q -l query -d "SQL query to execute" -r
complete -c psql_json -s t -l table -d "Table name for auto-generated query" -r -f -a "(__psql_json_get_tables)"
complete -c psql_json -s w -l where -d "WHERE clause for table queries" -r
complete -c psql_json -s p -l pretty -d "Pretty-print JSON output"
complete -c psql_json -s h -l help -d "Show help message"

# Common connection string examples
complete -c psql_json -n "__fish_seen_subcommand_from -c --connection" -a "'postgres://user:password@localhost:5432/database'" -d "Connection string template"
complete -c psql_json -n "__fish_seen_subcommand_from -c --connection" -a "'postgres://postgres:postgres@localhost:5432/postgres'" -d "Default PostgreSQL connection"

# Common SQL patterns for queries
complete -c psql_json -n "__fish_seen_subcommand_from -q --query" -a "'SELECT row_to_json(t) FROM table_name t'" -d "Basic row_to_json query"
complete -c psql_json -n "__fish_seen_subcommand_from -q --query" -a "'SELECT json_agg(row_to_json(t)) FROM table_name t'" -d "JSON array of all rows"
complete -c psql_json -n "__fish_seen_subcommand_from -q --query" -a "'SELECT row_to_json(t) FROM table_name t LIMIT 10'" -d "Limited row_to_json query"
