# Completions for psql_clear_tables function

complete -c psql_clear_tables -f -d "Clear all tables in a PostgreSQL database"

# Options
complete -c psql_clear_tables -s c -l connection -d "Database connection string" -r
complete -c psql_clear_tables -l cascade -d "Use CASCADE for foreign key constraints"
complete -c psql_clear_tables -l drop -d "Drop tables completely (removes structure)"
complete -c psql_clear_tables -l drop-functions -d "Also drop all functions/stored procedures"
complete -c psql_clear_tables -l include-migrations -d "Include migration tables (skipped by default)"
complete -c psql_clear_tables -s i -l interactive -d "Interactively select tables to keep"
complete -c psql_clear_tables -l clear-cache -d "Clear cached table selections"
complete -c psql_clear_tables -s y -l yes -d "Skip confirmation prompt"
complete -c psql_clear_tables -s h -l help -d "Show help message"

# Common connection string examples
complete -c psql_clear_tables -n "__fish_seen_subcommand_from -c --connection" -a "'postgres://user:password@localhost:5432/database'" -d "Connection string template"
complete -c psql_clear_tables -n "__fish_seen_subcommand_from -c --connection" -a "'postgres://postgres:postgres@localhost:5432/postgres'" -d "Default PostgreSQL connection"
