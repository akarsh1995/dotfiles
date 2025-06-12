# Function to execute PostgreSQL queries and return results as JSON
function psql_json
    # Parse arguments
    set -l connection_string ""
    set -l table ""
    set -l where_filters ""
    set -l help false
    set -l tsv false
    
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
            case "-t" "--table"
                set i (math $i + 1)
                if test $i -le (count $argv)
                    set table $argv[$i]
                end
            case "-w" "--where"
                # Collect all remaining arguments after --where as filter conditions
                set i (math $i + 1)
                while test $i -le (count $argv)
                    # Stop if we hit another flag
                    if string match -q -- "-*" $argv[$i]
                        set i (math $i - 1)  # Back up one to reprocess this arg
                        break
                    end
                    set where_filters $where_filters $argv[$i]
                    set i (math $i + 1)
                end
            case "--tsv"
                set tsv true
            case "-h" "--help"
                set help true
            case "*"
                # If no flag is specified, treat as table name
                if test -z "$table"
                    set table $argv[$i]
                end
        end
        set i (math $i + 1)
    end
    
    # Show help if requested
    if $help
        echo "Usage: psql_json [OPTIONS] [TABLE_NAME]"
        echo ""
        echo "Execute PostgreSQL queries on tables and return results as JSON."
        echo ""
        echo "Options:"
        echo "  -c, --connection STRING  Database connection string"
        echo "  -t, --table STRING       Table name to query"
        echo "  -w, --where FILTERS      Smart filters or raw SQL WHERE clause"
        echo "                           Smart syntax: column=value column>value column~pattern"
        echo "                           Use 'OR' to separate OR groups"
        echo "                           Operators: = != > < >= <= ~ (ILIKE) !~ (NOT ILIKE)"
        echo "  --tsv                    Output as TSV (Tab-Separated Values) for spreadsheets"
        echo "  -h, --help              Show this help message"
        echo ""
        echo "Connection String Format:"
        echo "  postgres://user:password@host:port/database?options"
        echo ""
        echo "Examples:"
        echo "  # Table-based query"
        echo "  psql_json -c 'postgres://user:pass@localhost:5432/mydb' -t users"
        echo ""
        echo "  # With smart filters (AND logic)"
        echo "  psql_json loans -w margin_issued=5 created_at>2025-02-01"
        echo ""
        echo "  # With smart filters (OR logic)"
        echo "  psql_json loans -w margin_issued=5 OR asset~%BTC%"
        echo ""
        echo "  # With smart filters (Mixed AND/OR)"
        echo "  psql_json loans -w margin_issued=5 created_at>2025-02-01 OR asset~%BTC%"
        echo ""
        echo "  # Traditional WHERE clause"
        echo "  psql_json -c 'postgres://user:pass@localhost:5432/mydb' \\"
        echo "            -t users -w \"id>100\""
        echo ""
        echo "  # Using environment variables"
        echo "  set -gx PSQL_CONNECTION 'postgres://user:pass@localhost:5432/mydb'"
        echo "  psql_json -t products -w \"price>50\""
        echo ""
        echo "  # Shorthand (table name without -t flag)"
        echo "  psql_json users"
        echo ""
        echo "  # TSV output for spreadsheets"
        echo "  psql_json users --tsv | pbcopy"
        return 0
    end
    
    # Check if psql is available
    if not command -sq psql
        echo "Error: psql command not found. Please install PostgreSQL client tools."
        return 1
    end
    
    # Check if jq is available for JSON processing
    if not command -sq jq
        echo "Error: jq command not found. Please install jq for JSON processing." >&2
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
     # Build query based on table name
    if test -z "$table"
        echo "Error: No table specified. Use -t option or provide table name as argument." >&2
        return 1
    end
    
    # Process WHERE filters if provided
    set -l where_clause ""
    if test -n "$where_filters"
        set where_clause (_psql_json_parse_filters $where_filters)
        if test $status -ne 0
            echo "Error: Failed to parse WHERE filters" >&2
            return 1
        end
    end

    # Auto-generate row_to_json query for table
    set -l query "SELECT row_to_json(t) FROM $table t"
    if test -n "$where_clause"
        set query "$query WHERE $where_clause"
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
        if $tsv
            echo "" # Empty TSV output
        else
            echo "[]" # Return empty JSON array for no results
        end
        return 0
    end
    
    # Process output based on format requested
    if $tsv
        # Convert JSON to TSV format for spreadsheets
        echo $result | jq -s -r '
            # Get all unique keys from all objects to create header
            (map(keys) | add | unique) as $cols |
            # Output header row
            ($cols | @tsv),
            # Output data rows  
            (.[] | [.[$cols[]]] | @tsv)
        '
    else
        # Always pretty print JSON array
        echo $result | jq -s . 2>/dev/null
    end
end

# Helper function to parse smart filters into SQL WHERE clause
function _psql_json_parse_filters
    set -l filters $argv
    
    # Check if this looks like smart filtering (contains operators) or raw SQL
    set -l has_operators false
    for filter in $filters
        if string match -q "*=*" -- $filter; or string match -q "*>*" -- $filter; or string match -q "*<*" -- $filter; or string match -q "*~*" -- $filter
            set has_operators true
            break
        end
    end
    
    # If no smart operators detected, treat as raw SQL
    if not $has_operators
        echo (string join " " $filters)
        return 0
    end
    
    # Join all filters into a single string for processing
    set -l filter_string (string join " " $filters)
    
    # Split by OR (case-insensitive) to get OR groups
    # First normalize the case by replacing " or " with " OR "
    set filter_string (string replace -a " or " " OR " $filter_string)
    set -l or_groups (string split " OR " $filter_string)
    set -l where_parts
    
    # Process each OR group
    for or_group in $or_groups
        # Split each OR group by spaces to get individual AND conditions
        set -l and_conditions (string split " " $or_group)
        set -l and_parts
        
        # Process each AND condition
        for condition in $and_conditions
            if test -z "$condition"
                continue
            end
            
            set -l sql_condition (_psql_json_parse_single_filter $condition)
            if test $status -eq 0; and test -n "$sql_condition"
                set and_parts $and_parts $sql_condition
            end
        end
        
        # Join AND conditions with AND
        if test (count $and_parts) -gt 0
            if test (count $and_parts) -eq 1
                set where_parts $where_parts $and_parts[1]
            else
                set where_parts $where_parts "("(string join " AND " $and_parts)")"
            end
        end
    end
    
    # Join OR groups with OR
    if test (count $where_parts) -gt 0
        echo (string join " OR " $where_parts)
        return 0
    else
        return 1
    end
end

# Helper function to parse a single filter condition
function _psql_json_parse_single_filter
    set -l condition $argv[1]
    
    # Define operator patterns and their SQL equivalents
    set -l operators "!~" "~" "!=" ">=" "<=" "=" ">" "<"
    set -l sql_ops "NOT ILIKE" "ILIKE" "!=" ">=" "<=" "=" ">" "<"
    
    # Find the operator in the condition
    for i in (seq (count $operators))
        set -l op $operators[$i]
        if string match -q "*$op*" -- $condition
            # Split on the operator
            set -l parts (string split -m 1 $op $condition)
            if test (count $parts) -eq 2
                set -l column (string trim $parts[1])
                set -l value (string trim $parts[2])
                set -l sql_op $sql_ops[$i]
                
                # Check if value is already quoted (single quotes)
                set -l is_quoted false
                if string match -q "'*'" -- $value
                    set is_quoted true
                    # Remove the surrounding quotes for processing
                    set value (string sub -s 2 -e -1 $value)
                end
                
                # Handle special cases for ILIKE patterns
                if test "$sql_op" = "ILIKE"; or test "$sql_op" = "NOT ILIKE"
                    # Always quote ILIKE values
                    set value "'$value'"
                # Handle NULL values (only if not originally quoted)
                else if not $is_quoted; and test "$value" = "NULL"; or test "$value" = "null"
                    if test "$sql_op" = "="
                        echo "$column IS NULL"
                        return 0
                    else if test "$sql_op" = "!="
                        echo "$column IS NOT NULL"
                        return 0
                    end
                # Handle values that were originally quoted - treat as strings
                else if $is_quoted
                    set value "'$value'"
                # Handle numeric values (don't quote if not originally quoted)
                else if string match -q -r "^[0-9]+(\.[0-9]+)?\$" -- $value
                    # Keep numeric values unquoted
                # Handle boolean values (only if not originally quoted)
                else if test "$value" = "true"; or test "$value" = "false"
                    # Keep boolean values unquoted
                # Handle date/timestamp values
                else if string match -q -r "^[0-9]{4}-[0-9]{2}-[0-9]{2}" -- $value
                    set value "'$value'"
                # Quote everything else
                else
                    set value "'$value'"
                end
                
                echo "$column $sql_op $value"
                return 0
            end
        end
    end
    
    # If no operator found, return error
    return 1
end
