# Disk cleanup — caches, build artifacts, and stale dev data.
#
#   cleanup                 # safe caches only (default)
#   cleanup --build         # + Gradle, Rust target dirs, .next/.sst/.open-next
#   cleanup --deep          # + Trash, AVDs, colima leftovers, HuggingFace, logs >30d
#   cleanup --node-modules  # + node_modules (keeps $CLEANUP_KEEP_PROJECTS)
#   cleanup --dry-run       # show what would be removed, delete nothing
#   cleanup status          # disk usage overview
#
# Flags combine: `cleanup --build --deep -n`

function cleanup --description "Reclaim disk space from caches, build artifacts, and stale data"

    set -l log_file $HOME/.config/scripts/cleanup.log
    set -l dry 0
    set -l build 0
    set -l deep 0
    set -l node_modules 0

    # Projects whose node_modules are never touched by --node-modules.
    if not set -q CLEANUP_KEEP_PROJECTS
        set -g CLEANUP_KEEP_PROJECTS zapkeyz-frontend trading_bot
    end

    for arg in $argv
        switch $arg
            case -n --dry-run
                set dry 1
            case -b --build
                set build 1
            case -d --deep
                set build 1
                set deep 1
            case --node-modules
                set node_modules 1
            case status
                __cleanup_status
                return 0
            case -h --help
                __cleanup_help
                return 0
            case '*'
                echo "cleanup: unknown option '$arg'" >&2
                __cleanup_help >&2
                return 1
        end
    end

    set -l free_before (df -k /System/Volumes/Data | awk 'NR==2 {print $4}')
    set -l started (date "+%Y-%m-%d %H:%M:%S")

    if test $dry -eq 1
        echo "DRY RUN — nothing will be deleted"
    end
    echo ""

    # ---------------------------------------------------------------- caches
    set -l safe_paths \
        $HOME/.npm/_cacache \
        $HOME/.npm/_npx \
        $HOME/.cache/uv \
        $HOME/.cache/.bun/install \
        $HOME/.cache/bun \
        $HOME/.cache/pip \
        $HOME/Library/Caches/pip \
        $HOME/.cache/ccache \
        $HOME/Library/Caches/Google/Chrome \
        $HOME/Library/Caches/Telegram \
        $HOME/Library/Caches/Homebrew

    echo "== Caches"
    set -l freed (__cleanup_purge $dry $safe_paths)

    # Homebrew keeps old Cellar versions outside its cache dir.
    if type -q brew
        if test $dry -eq 1
            echo "  would run         brew cleanup --prune=all" >&2
        else
            brew cleanup --prune=all >/dev/null 2>&1
            echo "  done              brew old versions (brew cleanup)" >&2
        end
    end

    # ------------------------------------------------------- build artifacts
    if test $build -eq 1
        echo ""
        echo "== Build artifacts"

        set -l build_paths $HOME/.gradle/caches

        # Rust target dirs worth clearing (>500 MB)
        for target in (find $HOME/Programming -maxdepth 4 -type d -name target 2>/dev/null)
            set -l kb (du -sk $target 2>/dev/null | awk '{print $1}')
            if test -n "$kb"; and test $kb -gt 512000
                set build_paths $build_paths $target
            end
        end

        # JS build output
        for dir in (find $HOME/Programming -maxdepth 5 -type d \( -name .next -o -name .sst -o -name .open-next \) -prune -print 2>/dev/null)
            set build_paths $build_paths $dir
        end

        # node_modules outside the keep-list
        if test $node_modules -eq 1
            for nm in (find $HOME/Programming -type d -name node_modules -prune 2>/dev/null)
                set -l keep 0
                for project in $CLEANUP_KEEP_PROJECTS
                    string match -q "*/$project/*" -- $nm; and set keep 1
                end
                test $keep -eq 0; and set build_paths $build_paths $nm
            end
        end

        set freed (math "$freed + "(__cleanup_purge $dry $build_paths))
    end

    # ------------------------------------------------------------- deep cuts
    if test $deep -eq 1
        echo ""
        echo "== Deep cuts"

        set -l deep_paths \
            $HOME/.Trash \
            $HOME/.android/avd \
            $HOME/.config/.android/avd \
            $HOME/.config/colima/_lima/_disks \
            $HOME/.cache/huggingface \
            $HOME/.cache/puppeteer \
            $HOME/.cache/hyperframes \
            $HOME/.pulumi/plugins \
            $HOME/Library/Application\ Support/sst/plugins

        set freed (math "$freed + "(__cleanup_purge $dry $deep_paths))

        # Conversation history older than 30 days (keeps config and credentials)
        set -l history_dirs \
            $HOME/.gemini/antigravity/conversations \
            $HOME/.gemini/antigravity/brain \
            $HOME/.gemini/antigravity-ide/conversations \
            $HOME/.gemini/antigravity-ide/brain \
            $HOME/.reasonix/projects \
            $HOME/.reasonix/desktop-sessions-v5 \
            $HOME/.codex/sessions

        set freed (math "$freed + "(__cleanup_prune_old 30 $dry $history_dirs))
    end

    # ---------------------------------------------------------------- report
    set -l free_after (df -k /System/Volumes/Data | awk 'NR==2 {print $4}')
    set -l gained (math "$free_after - $free_before")

    echo ""
    if test $dry -eq 1
        printf "Would free: ~%.1f GB\n" (math "$freed / 1048576")
    else
        printf "Reclaimed:  %.1f GB\n" (math "$freed / 1048576")
        printf "Free space: %.1f GB → %.1f GB\n" (math "$free_before / 1048576") (math "$free_after / 1048576")
    end

    if not test -d (dirname $log_file)
        mkdir -p (dirname $log_file)
    end
    echo "$started | dry=$dry build=$build deep=$deep | $CLEANUP_KEEP_PROJECTS | freed_kb=$freed | disk_gain_kb=$gained" >>$log_file
end


# --------------------------------------------------------------------- helpers

function __cleanup_purge --description "Remove paths and report sizes. Args: dry_run, paths..."
    set -l dry $argv[1]
    set -l total 0

    for path in $argv[2..-1]
        test -e $path; or continue

        set -l kb (du -sk $path 2>/dev/null | awk '{print $1}')
        test -z "$kb"; and set kb 0
        set total (math "$total + $kb")

        set -l short (string replace -r "^$HOME" "~" -- $path)
        if test $dry -eq 1
            printf "  would free %-9s %s\n" (__cleanup_human $kb) $short >&2
        else
            rm -rf -- $path 2>/dev/null
            printf "  freed %-14s %s\n" (__cleanup_human $kb) $short >&2
        end
    end

    echo $total
end


function __cleanup_prune_old --description "Delete files older than N days. Args: days, dry_run, dirs..."
    set -l days $argv[1]
    set -l dry $argv[2]
    set -l total 0

    for dir in $argv[3..-1]
        test -d $dir; or continue

        set -l kb (find $dir -type f -mtime +$days -exec du -sk {} + 2>/dev/null | awk '{s+=$1} END {print s+0}')
        set total (math "$total + $kb")

        set -l short (string replace -r "^$HOME" "~" -- $dir)
        if test $dry -eq 1
            printf "  would free %-9s %s (>%sd)\n" (__cleanup_human $kb) $short $days >&2
        else
            find $dir -type f -mtime +$days -delete 2>/dev/null
            printf "  freed %-14s %s (>%sd)\n" (__cleanup_human $kb) $short $days >&2
        end
    end

    echo $total
end


function __cleanup_human --description "Format a size in KB as human-readable"
    set -l kb $argv[1]
    if test $kb -ge 1048576
        printf "%.1fG" (math "$kb / 1048576")
    else if test $kb -ge 1024
        printf "%.0fM" (math "$kb / 1024")
    else
        printf "%dK" $kb
    end
end


function __cleanup_status --description "Show disk usage overview"
    echo "Disk:"
    df -h /System/Volumes/Data | awk 'NR==1 || NR==2'
    echo ""
    echo "Top consumers in ~:"
    du -xh -d 1 $HOME 2>/dev/null | sort -rh | head -12
end


function __cleanup_help --description "Show cleanup usage"
    echo "usage: cleanup [--build] [--deep] [--node-modules] [--dry-run]"
    echo "       cleanup status | --help"
    echo ""
    echo "  (no flags)        safe caches only: npm, uv, bun, pip, ccache, Chrome, Telegram, Homebrew"
    echo "  -b, --build       + Gradle, Rust target dirs >500MB, .next/.sst/.open-next"
    echo "  --node-modules    + node_modules except \$CLEANUP_KEEP_PROJECTS"
    echo "  -d, --deep        implies --build, + Trash, AVDs, colima disks, HuggingFace, logs >30d"
    echo "  -n, --dry-run     show what would be removed, delete nothing"
    echo "  status            disk usage overview"
    echo ""
    echo "Override keep-list: set -g CLEANUP_KEEP_PROJECTS project-a project-b"
end
