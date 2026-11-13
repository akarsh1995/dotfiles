function fisher-files --description "Show which fish files belong to each fisher plugin"
    set -l show_stale 0
    set -l filters

    for arg in $argv
        switch $arg
            case -s --stale
                set show_stale 1
            case -h --help
                echo "usage: fisher-files [--stale] [plugin-filter]"
                echo
                echo "Lists every file fisher installed, grouped by plugin."
                echo "  --stale   only plugin-owned files that git still tracks"
                return 0
            case '-*'
                echo "fisher-files: unknown option '$arg'" >&2
                return 1
            case '*'
                set filters $filters $arg
        end
    end

    set -l repo (git -C $__fish_config_dir rev-parse --show-toplevel 2>/dev/null)
    test -n "$repo"; or set repo (path normalize $__fish_config_dir/..)

    set -l tracked
    if test $show_stale -eq 1
        set tracked (git -C $repo ls-files)
    end

    set -l found 0
    for var in (set --names --universal | string match -r '^_fisher_.*_files$')
        set -l encoded (string replace -r '^_fisher_' '' -- $var | string replace -r '_files$' '')
        set -l plugin (string unescape --style=var -- $encoded)

        if test (count $filters) -gt 0
            set -l matched 0
            for filter in $filters
                string match -q "*$filter*" -- $plugin; and set matched 1
            end
            test $matched -eq 1; or continue
        end

        set -l files
        for raw in $$var
            set -l path (string replace -- '~' $HOME $raw)
            set -l rel (string replace -- "$repo/" '' $path)
            if test $show_stale -eq 1
                contains -- $rel $tracked; or continue
            end
            set files $files $rel
        end

        test (count $files) -gt 0; or continue
        set found (math $found + 1)

        echo $plugin" ("(count $files)" file(s))"
        printf '  %s\n' $files
    end

    if test $found -eq 0
        if test $show_stale -eq 1
            echo "no plugin-owned files are tracked by git"
        else
            echo "no fisher plugin manifests found"
            echo "install plugins with: fisher install <plugin>"
        end
    end
end
