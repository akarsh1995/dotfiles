# Function to clear all tables in a PostgreSQL database
function psql_clear_tables
    # Parse arguments
    set -l connection_string ""
    set -l help false
    set -l cascade false
    set -l yes false
    set -l include_migrations false
    set -l interactive false
    set -l clear_cache false
    set -l drop false
    set -l drop_functions false
    
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
            case "--cascade"
                set cascade true
            case "-y" "--yes"
                set yes true
            case "-i" "--interactive"
                set interactive true
            case "--clear-cache"
                set clear_cache true
            case "--include-migrations"
                set include_migrations true
            case "--drop"
                set drop true
            case "--drop-functions"
                set drop_functions true
            case "-h" "--help"
                set help true
        end
        set i (math $i + 1)
    end
    
    # Show help if requested
    if $help
        echo "Usage: psql_clear_tables [OPTIONS]"
        echo ""
        echo "Clear all tables in a PostgreSQL database by truncating or dropping them."
        echo ""
        echo "Options:"
        echo "  -c, --connection STRING  Database connection string"
        echo "  --cascade                Use CASCADE to handle foreign key constraints"
        echo "  --drop                   Drop tables completely (removes structure, not just data)"
        echo "  --drop-functions         Also drop all functions/stored procedures"
        echo "  --include-migrations     Include migration tables (skipped by default)"
        echo "  -i, --interactive        Interactively select tables to keep (cached for next time)"
        echo "  --clear-cache            Clear cached table selections"
        echo "  -y, --yes                Skip confirmation prompt"
        echo "  -h, --help              Show this help message"
        echo ""
        echo "Connection String Format:"
        echo "  postgres://user:password@host:port/database?options"
        echo ""
        echo "Examples:"
        echo "  # Clear all tables with confirmation (truncate)"
        echo "  psql_clear_tables -c 'postgres://user:pass@localhost:5432/mydb'"
        echo ""
        echo "  # Drop all tables (removes structure)"
        echo "  psql_clear_tables -c 'postgres://user:pass@localhost:5432/mydb' --drop"
        echo ""
        echo "  # Drop all tables and functions"
        echo "  psql_clear_tables -c 'postgres://user:pass@localhost:5432/mydb' --drop --drop-functions"
        echo ""
        echo "  # Clear all tables with CASCADE (handles foreign keys)"
        echo "  psql_clear_tables -c 'postgres://user:pass@localhost:5432/mydb' --cascade"
        echo ""
        echo "  # Skip confirmation prompt"
        echo "  psql_clear_tables -c 'postgres://user:pass@localhost:5432/mydb' --yes"
        echo ""
        echo "  # Using environment variables"
        echo "  set -gx PSQL_CONNECTION 'postgres://user:pass@localhost:5432/mydb'"
        echo "  psql_clear_tables"
        echo ""
        echo "  # Include migration tables"
        echo "  psql_clear_tables --include-migrations"
        echo ""
        echo "  # Interactive mode - select tables to keep"
        echo "  psql_clear_tables --interactive"
        echo ""
        echo "  # Clear cached selections and start fresh"
        echo "  psql_clear_tables --clear-cache --interactive"
        echo ""
        echo "NOTE: Migration tables are skipped by default (e.g., schema_migrations, migrations)."
        echo "      Use --include-migrations to clear them as well."
        echo ""
        echo "NOTE: Use --interactive to select which tables to keep. Your selections are cached"
        echo "      and remembered for next time. Use --clear-cache to reset selections."
        echo ""
        echo "NOTE: By default, TRUNCATE is used (clears data, keeps structure)."
        echo "      Use --drop to completely remove tables including their structure."
        echo ""
        echo "WARNING: This operation will delete data from all tables in the database!"
        echo "         With --drop, it will also remove the table structures!"
        echo "         This action cannot be undone. Use with caution!"
        return 0
    end
    
    # Define cache file location
    set -l cache_dir "$HOME/.cache/fish/psql_clear_tables"
    set -l cache_file "$cache_dir/kept_tables.txt"
    
    # Handle cache clearing
    if $clear_cache
        if test -f "$cache_file"
            rm "$cache_file"
            echo "✓ Cleared cached table selections."
        else
            echo "No cache file found."
        end
        
        # If only clearing cache, exit
        if not $interactive
            return 0
        end
    end
    
    # Check if psql is available
    if not command -sq psql
        echo "Error: psql command not found. Please install PostgreSQL client tools." >&2
        return 1
    end
    
    # Check if fzf is available for interactive mode
    if $interactive; and not command -sq fzf
        echo "Error: fzf command not found. Please install fzf for interactive mode." >&2
        return 1
    end
    
    # Get connection string from environment if not provided
    if test -z "$connection_string"
        if set -q PSQL_CONNECTION
            set connection_string $PSQL_CONNECTION
        else if set -q DATABASE_URL
            set connection_string $DATABASE_URL
        else
            echo "Error: No connection string provided. Use -c option or set PSQL_CONNECTION environment variable." >&2
            return 1
        end
    end
    
    # Query to get all table names from public schema
    set -l tables_query "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE' ORDER BY table_name;"
    
    # Get list of tables
    set -l tables (psql -t "$connection_string" -c "$tables_query" 2>/dev/null | string trim | string match -v "")
    set -l psql_status $status
    
    # Don't fail if we can't retrieve tables - we might still want to drop functions
    if test $psql_status -ne 0
        # Only show warning if we're not just dropping functions
        if not $drop_functions; or not $drop
            echo "Warning: Could not retrieve table list. Database may be empty or connection issue." >&2
        end
        set tables
    end
    
    # Check if there are any tables
    if test (count $tables) -eq 0
        echo "No tables found in the database."
        
        # If --drop-functions is set, still proceed to drop functions
        if $drop_functions; and $drop
            echo ""
            _psql_drop_functions "$connection_string" $cascade
            return $status
        end
        
        return 0
    end
    
    # Filter out migration tables unless --include-migrations is set
    if not $include_migrations
        set -l migration_patterns "schema_migrations" "migrations" "_prisma_migrations" "knex_migrations" "knex_migrations_lock" "flyway_schema_history" "alembic_version" "django_migrations"
        set -l filtered_tables
        
        for table in $tables
            set -l is_migration false
            for pattern in $migration_patterns
                if test "$table" = "$pattern"
                    set is_migration true
                    break
                end
            end
            
            if not $is_migration
                set filtered_tables $filtered_tables $table
            end
        end
        
        set -l skipped_count (math (count $tables) - (count $filtered_tables))
        set tables $filtered_tables
        
        if test $skipped_count -gt 0
            echo "Skipping $skipped_count migration table(s). Use --include-migrations to clear them."
            echo ""
        end
    end
    
    # Check if there are any tables left after filtering
    if test (count $tables) -eq 0
        echo "No tables to clear (all tables are migration tables)."
        echo "Use --include-migrations to clear migration tables."
        
        # If --drop-functions is set, still proceed to drop functions
        if $drop_functions; and $drop
            echo ""
            _psql_drop_functions "$connection_string" $cascade
            return $status
        end
        
        return 0
    end
    
    # Interactive mode: let user select tables to keep
    if $interactive
        if $drop
            echo "Select tables to KEEP (they will NOT be dropped):"
        else
            echo "Select tables to KEEP (they will NOT be cleared):"
        end
        echo "Use TAB to select/deselect, ENTER to confirm"
        echo ""
        
        # Load previously kept tables if cache exists
        set -l previously_kept
        if test -f "$cache_file"
            set previously_kept (cat "$cache_file" 2>/dev/null | string trim | string match -v "")
        end
        
        # Use fzf for multi-select with preview
        set -l kept_tables
        if test (count $previously_kept) -gt 0
            # Show previously kept tables in header
            set -l prev_list (string join ", " $previously_kept)
            set kept_tables (printf '%s\n' $tables | fzf --multi --prompt="Tables to keep > " \
                --header="Previously kept: $prev_list" \
                --bind="tab:toggle+down" \
                --preview="echo 'This table will be KEPT (not cleared)'")
        else
            set kept_tables (printf '%s\n' $tables | fzf --multi --prompt="Tables to keep > " \
                --header="Select tables to KEEP (not clear)" \
                --bind="tab:toggle+down" \
                --preview="echo 'This table will be KEPT (not cleared)'")
        end
        
        # Check if user cancelled
        if test $status -ne 0
            echo "Operation cancelled."
            return 0
        end
        
        # Save kept tables to cache
        if test (count $kept_tables) -gt 0
            mkdir -p "$cache_dir"
            printf '%s\n' $kept_tables > "$cache_file"
            echo ""
            echo "✓ Saved "(count $kept_tables)" table(s) to keep for next time."
        else
            # If no tables kept, remove cache file
            test -f "$cache_file"; and rm "$cache_file"
        end
        
        # Filter out kept tables from tables to clear
        set -l tables_to_clear
        for table in $tables
            set -l should_keep false
            for kept in $kept_tables
                if test "$table" = "$kept"
                    set should_keep true
                    break
                end
            end
            if not $should_keep
                set tables_to_clear $tables_to_clear $table
            end
        end
        
        set tables $tables_to_clear
        
        # Check if there are any tables left to clear
        if test (count $tables) -eq 0
            echo ""
            echo "No tables to clear (all tables are marked to keep)."
            
            # If --drop-functions is set, still proceed to drop functions
            if $drop_functions; and $drop
                echo ""
                _psql_drop_functions "$connection_string" $cascade
                return $status
            end
            
            return 0
        end
        
        echo ""
    else
        # Non-interactive mode: load cached kept tables and apply them
        if test -f "$cache_file"
            set -l kept_tables (cat "$cache_file" 2>/dev/null | string trim | string match -v "")
            
            if test (count $kept_tables) -gt 0
                # Filter out kept tables from tables to clear
                set -l tables_to_clear
                for table in $tables
                    set -l should_keep false
                    for kept in $kept_tables
                        if test "$table" = "$kept"
                            set should_keep true
                            break
                        end
                    end
                    if not $should_keep
                        set tables_to_clear $tables_to_clear $table
                    end
                end
                
                set -l kept_count (math (count $tables) - (count $tables_to_clear))
                set tables $tables_to_clear
                
                if test $kept_count -gt 0
                    echo "Keeping $kept_count cached table(s). Use --clear-cache to reset."
                    echo ""
                end
                
                # Check if there are any tables left to clear
                if test (count $tables) -eq 0
                    echo "No tables to clear (all tables are marked to keep)."
                    echo "Use --clear-cache to reset, or --interactive to change selections."
                    
                    # If --drop-functions is set, still proceed to drop functions
                    if $drop_functions; and $drop
                        echo ""
                        _psql_drop_functions "$connection_string" $cascade
                        return $status
                    end
                    
                    return 0
                end
            end
        end
    end
    
    # Display tables that will be cleared or dropped
    if $drop
        echo "The following tables will be DROPPED (structure removed):"
    else
        echo "The following tables will be CLEARED (data removed):"
    end
    for table in $tables
        echo "  - $table"
    end
    echo ""
    echo "Total: "(count $tables)" table(s)"
    echo ""
    
    # Ask for confirmation unless --yes was provided
    if not $yes
        if $drop
            echo "WARNING: This will DROP these tables (removes structure and data)!"
            if $drop_functions
                echo "         AND drop all database functions!"
            end
        else
            echo "WARNING: This will delete ALL data from these tables!"
        end
        echo -n "Are you sure you want to continue? (yes/no): "
        read -l confirmation
        
        if test "$confirmation" != "yes"
            echo "Operation cancelled."
            return 0
        end
    end
    
    # Build CASCADE option
    set -l cascade_option ""
    if $cascade
        set cascade_option " CASCADE"
    end
    
    echo ""
    
    # Drop functions first if requested (before dropping tables)
    if $drop_functions
        if $drop
            _psql_drop_functions "$connection_string" $cascade
            if test $status -ne 0
                return 1
            end
        else
            echo "Note: --drop-functions requires --drop flag. Skipping function drops."
            echo ""
        end
    end
    
    if $drop
        # For DROP, we need to drop each table individually
        echo "Dropping tables..."
        set -l failed_tables
        
        for table in $tables
            set -l drop_query "DROP TABLE IF EXISTS $table$cascade_option;"
            set -l result (psql "$connection_string" -c "$drop_query" 2>&1)
            set -l psql_status $status
            
            if test $psql_status -ne 0
                set failed_tables $failed_tables $table
                echo "✗ Failed to drop $table" >&2
                echo "  $result" >&2
            end
        end
        
        if test (count $failed_tables) -gt 0
            echo ""
            echo "Error: Failed to drop "(count $failed_tables)" table(s)." >&2
            
            # Provide helpful error message for foreign key constraints
            if string match -q "*foreign key*" -- $result; or string match -q "*depends on*" -- $result
                echo "" >&2
                echo "Tip: Use --cascade flag to automatically handle dependencies." >&2
            end
            
            return 1
        end
        
        echo "✓ Successfully dropped "(count $tables)" table(s)."
        return 0
    else
        # Join table names with commas for TRUNCATE
        set -l table_list (string join ", " $tables)
        set -l truncate_query "TRUNCATE TABLE $table_list$cascade_option;"
        
        echo "Clearing tables..."
        
        # Execute TRUNCATE command
        set -l result (psql "$connection_string" -c "$truncate_query" 2>&1)
        set -l psql_status $status
        
        if test $psql_status -ne 0
            echo "Error: Failed to clear tables." >&2
            echo $result >&2
            
            # Provide helpful error message for foreign key constraints
            if string match -q "*foreign key*" -- $result
                echo "" >&2
                echo "Tip: Use --cascade flag to automatically handle foreign key constraints." >&2
            end
            
            return 1
        end
        
        echo "✓ Successfully cleared "(count $tables)" table(s)."
        return 0
    end
end

# Helper function to drop all database functions
function _psql_drop_functions
    set -l connection_string $argv[1]
    set -l cascade $argv[2]
    
    echo ""
    echo "Retrieving database functions..."
    
    # Simpler query - just get the full DROP statement directly from PostgreSQL
    set -l functions_query "SELECT 
        'DROP ' || 
        CASE p.prokind
            WHEN 'f' THEN 'FUNCTION'
            WHEN 'p' THEN 'PROCEDURE'
            WHEN 'a' THEN 'AGGREGATE'
            WHEN 'w' THEN 'FUNCTION'
        END || ' IF EXISTS ' ||
        n.nspname || '.' || p.proname || '(' || 
        pg_catalog.pg_get_function_identity_arguments(p.oid) || ');' as drop_statement
    FROM pg_catalog.pg_proc p
    LEFT JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
    AND p.prokind IN ('f', 'p', 'a', 'w')
    ORDER BY p.proname;"
    
    # Get list of DROP statements
    set -l drop_statements (psql -t "$connection_string" -c "$functions_query" 2>&1 | string trim | string match -v "")
    set -l psql_status $status
    
    if test $psql_status -ne 0
        echo "Error: Failed to retrieve function list from database." >&2
        echo $drop_statements >&2
        return 1
    end
    
    # Check if there are any functions
    if test (count $drop_statements) -eq 0
        echo "No functions found in the database."
        return 0
    end
    
    echo "Found "(count $drop_statements)" function(s)/procedure(s) to drop."
    
    # Add CASCADE if requested
    set -l cascade_option ""
    if $cascade
        set cascade_option " CASCADE"
    end
    
    echo "Dropping functions..."
    set -l failed_count 0
    set -l dropped_count 0
    
    for drop_stmt in $drop_statements
        # Add CASCADE if requested (replace the semicolon)
        if $cascade
            set drop_stmt (string replace -r ';$' "$cascade_option;" $drop_stmt)
        end
        
        set -l result (psql "$connection_string" -c "$drop_stmt" 2>&1)
        set -l psql_status $status
        
        if test $psql_status -ne 0
            set failed_count (math $failed_count + 1)
            echo "✗ Failed to execute: $drop_stmt" >&2
            echo "  $result" >&2
        else
            set dropped_count (math $dropped_count + 1)
        end
    end
    
    if test $failed_count -gt 0
        echo ""
        echo "Warning: Failed to drop $failed_count function(s)." >&2
        if test $dropped_count -gt 0
            echo "Successfully dropped $dropped_count function(s)."
        end
        return 0
    end
    
    echo "✓ Successfully dropped $dropped_count function(s)/procedure(s)."
    return 0
end
