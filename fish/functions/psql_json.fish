# Function to execute PostgreSQL queries and return results as JSON
function psql_json
    # Parse arguments
    set -l connection_string ""
    set -l query ""
    set -l table ""
    set -l where_clause ""
    set -l help false
    set -l pretty false
    
    # Parse command line arguments
    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case "-c" "--connection"
                set i (math $i + 1)
                if test $i -le (count $argv)
                    set -l raw_connection $argv[$i]
                    # Check if it's a command substitution and evaluate it
                    if string match -q "(*)" -- "$raw_connection"
                        # Extract the command inside parentheses and evaluate it
                        set -l inner_cmd (string sub -s 2 -e -1 "$raw_connection")
                        set connection_string (eval $inner_cmd 2>/dev/null)
                    else
                        set connection_string $raw_connection
                    end
                end
            case "-q" "--query"
                set i (math $i + 1)
                if test $i -le (count $argv)
                    set query $argv[$i]
                end
            case "-t" "--table"
                set i (math $i + 1)
                if test $i -le (count $argv)
                    set table $argv[$i]
                end
            case "-w" "--where"
                set i (math $i + 1)
                if test $i -le (count $argv)
                    set where_clause $argv[$i]
                end
            case "-p" "--pretty"
                set pretty true
            case "-h" "--help"
                set help true
            case "*"
                # If no flag is specified, treat as query
                if test -z "$query"
                    set query $argv[$i]
                end
        end
        set i (math $i + 1)
    end
    
    # Show help if requested
    if $help
        echo "Usage: psql_json [OPTIONS] [QUERY]"
        echo ""
        echo "Execute PostgreSQL queries and return results as JSON."
        echo ""
        echo "Options:"
        echo "  -c, --connection STRING  Database connection string"
        echo "  -q, --query STRING       SQL query to execute"
        echo "  -t, --table STRING       Table name (auto-generates row_to_json query)"
        echo "  -w, --where STRING       WHERE clause for table queries"
        echo "  -p, --pretty             Pretty-print JSON output"
        echo "  -h, --help              Show this help message"
        echo ""
        echo "Connection String Format:"
        echo "  postgres://user:password@host:port/database?options"
        echo ""
        echo "Examples:"
        echo "  # Direct query"
        echo "  psql_json -c 'postgres://user:pass@localhost:5432/mydb' \\"
        echo "            -q 'SELECT row_to_json(u) FROM users u LIMIT 5'"
        echo ""
        echo "  # Table-based query"
        echo "  psql_json -c 'postgres://user:pass@localhost:5432/mydb' \\"
        echo "            -t users -w \"id > 100\""
        echo ""
        echo "  # Using environment variables"
        echo "  set -gx PSQL_CONNECTION 'postgres://user:pass@localhost:5432/mydb'"
        echo "  psql_json -t products -w \"price > 50\""
        echo ""
        echo "  # Pretty-printed output"
        echo "  psql_json -c 'postgres://...' -t users --pretty"
        return 0
    end
    
    # Check if psql is available
    if not command -sq psql
        echo "Error: psql command not found. Please install PostgreSQL client tools."
        return 1
    end
    
    # Check if jq is available
    if not command -sq jq
        echo "Error: jq command not found. Please install jq for JSON processing."
        return 1
    end
    
    # Get connection string from environment if not provided
    if test -z "$connection_string"
        if set -q PSQL_CONNECTION
            set connection_string $PSQL_CONNECTION
        else if set -q DATABASE_URL
            set connection_string $DATABASE_URL
        else
            echo "Error: No connection string provided. Use -c option or set PSQL_CONNECTION environment variable."
            return 1
        end
    end
    
    # Build query based on options
    if test -n "$table" -a -z "$query"
        # Auto-generate row_to_json query for table
        set query "SELECT row_to_json(t) FROM $table t"
        if test -n "$where_clause"
            set query "$query WHERE $where_clause"
        end
    end
    
    # Validate that we have a query
    if test -z "$query"
        echo "Error: No query specified. Use -q option or -t option with table name."
        return 1
    end
    
    # Execute the query
    set -l result (psql -t "$connection_string" -c "$query" 2>&1)
    set -l psql_status $status
    
    if test $psql_status -ne 0
        echo "Error executing query:" >&2
        echo $result >&2
        return 1
    end
    
    # Clean up the result (remove leading/trailing whitespace)
    set result (echo $result | string trim)
    
    # Check if result is empty
    if test -z "$result"
        echo "[]" # Return empty JSON array for no results
        return 0
    end
    
    # Process and output JSON - always use jq for clean JSON
    if $pretty
        # Pretty print JSON
        for line in $result
            echo $line | jq . 2>/dev/null || echo $line | jq -s .
        end
    else
        # Compact JSON output
        for line in $result
            echo $line | jq -c . 2>/dev/null || echo $line | jq -c -s .
        end
    end
end
