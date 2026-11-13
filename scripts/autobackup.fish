#!/usr/bin/env fish
# Hourly safety net for the dotfiles repo at ~/.config.
#
#   autobackup.fish                 # refresh manifests, commit, push
#   autobackup.fish --dry-run       # show what would happen, change nothing
#   autobackup.fish --no-manifests  # skip brew/fisher refresh
#   autobackup.fish status          # branch state + recent log lines
#   autobackup.fish log             # tail the log
#
# GitHub (origin) is canonical. Codeberg is a best-effort mirror: a failed
# mirror push is logged but never fails the backup.

set -g repo $HOME/.config
set -g branch main
set -g log_file $repo/scripts/autobackup.log
set -g lock_dir $repo/.git/autobackup.lock
set -g dry_run 0
set -g refresh_manifests 1

# ------------------------------------------------------------------ helpers
function __log --argument-names message
    set -l line (date "+%Y-%m-%d %H:%M:%S")" | "$message
    if test $dry_run -eq 1
        echo $line
    else
        echo $line >>$log_file
    end
end

function __notify --argument-names message
    if test (uname -s) = Darwin; and command -q osascript
        osascript -e "display notification \"$message\" with title \"Dotfiles backup\"" >/dev/null 2>&1
    else if command -q notify-send
        notify-send "Dotfiles backup" "$message" >/dev/null 2>&1
    end
end

function __rotate_log
    test $dry_run -eq 0; or return 0
    test -f $log_file; or return 0
    if test (wc -c <$log_file | string trim) -gt 524288
        set -l tmp $log_file.tmp
        tail -n 400 $log_file >$tmp; and mv $tmp $log_file
    end
end

function __acquire_lock
    if test -d $lock_dir
        set -l old_pid (cat $lock_dir/pid 2>/dev/null | string trim)
        if test -n "$old_pid"; and kill -0 $old_pid 2>/dev/null
            __log "another backup is already running (pid $old_pid); skipping"
            return 1
        end
        # Stale lock from a killed/crashed run.
        rm -rf $lock_dir
    end
    mkdir -p $lock_dir; or return 1
    echo $fish_pid >$lock_dir/pid
    return 0
end

function __release_lock
    rm -rf $lock_dir
end

function __refresh_manifests
    if test $dry_run -eq 1
        __log "manifest refresh skipped (dry run)"
        return 0
    end

    if command -q brew
        # installed_on_request keeps explicitly installed tools that also happen
        # to be dependencies of others (fish, gnupg, ...). Fall back to leaves.
        set -l formulae
        set -l casks
        if command -q jq
            set formulae (brew info --json=v2 --installed --formula 2>/dev/null \
                | jq -r '.formulae[] | select(.installed[0].installed_on_request == true) | .full_name' \
                | sort)
            set casks (brew info --json=v2 --installed --cask 2>/dev/null \
                | jq -r '.casks[].full_token' \
                | sort \
                | string replace -r '^' 'cask:')
        else
            set formulae (brew leaves | sort)
            set casks (brew list --cask 2>/dev/null | sort | string replace -r '^' 'cask:')
        end

        set -l packages $formulae $casks
        if test (count $packages) -gt 0
            printf '%s\n' $packages >$repo/brew/brew-packages
            __log "refreshed brew/brew-packages ("(count $formulae)" formulae, "(count $casks)" casks)"
        end
    else
        __log "brew not found; skipping brew manifest"
    end

    if type -q fisher
        set -l plugins (fisher list 2>/dev/null | sort)
        if test (count $plugins) -gt 0
            printf '%s\n' $plugins >$repo/fish/fish_plugins
            __log "refreshed fish/fish_plugins ("(count $plugins)" plugins)"
        end
    else
        __log "fisher not found; skipping fish manifest"
    end
end

function __commit_changes
    set -l changes (git status --porcelain)
    if test (count $changes) -eq 0
        __log "no local changes"
        return 0
    end

    if test $dry_run -eq 1
        __log "would commit "(count $changes)" changed path(s): "(string join ", " $changes)
        return 0
    end

    __log "staging "(count $changes)" changed path(s)"
    git add -A
    or begin
        __log "git add failed"
        __notify "git add failed - see scripts/autobackup.log"
        return 1
    end

    set -l message "Auto backup on "(date "+%Y-%m-%d %H:%M:%S")
    git -c commit.gpgsign=true commit -S -m $message >>$log_file 2>&1
    set -l rc $status
    if test $rc -ne 0
        __log "signed commit failed (exit $rc); changes left staged for the next run"
        __log "if this repeats, unlock the GPG key (pinentry) so launchd can sign"
        __notify "Signed commit failed - unlock your GPG key"
        return 1
    end
    __log "committed: $message"
    return 0
end

function __push_to --argument-names remote
    set -l ahead (git rev-list --count $remote/$branch..HEAD 2>/dev/null | string trim)
    if test -z "$ahead"
        __log "cannot compare against $remote/$branch"
        return 1
    end
    if test "$ahead" -eq 0
        __log "$remote is up to date"
        return 0
    end
    if test $dry_run -eq 1
        __log "would push $ahead commit(s) to $remote"
        return 0
    end
    git push --quiet $remote $branch >>$log_file 2>&1
    or begin
        __log "push to $remote failed"
        return 1
    end
    __log "pushed $ahead commit(s) to $remote"
    return 0
end

function __sync_and_push
    # Rebase onto origin if another machine pushed first.
    if git fetch --quiet origin $branch 2>/dev/null
        set -l behind (git rev-list --count HEAD..origin/$branch 2>/dev/null | string trim)
        if test -n "$behind"; and test "$behind" -gt 0
            __log "$behind commit(s) behind origin; rebasing"
            if test $dry_run -eq 0
                git pull --rebase --autostash --quiet origin $branch >>$log_file 2>&1
                or begin
                    __log "rebase failed; aborting rebase and leaving the repo untouched"
                    git rebase --abort >/dev/null 2>&1
                    __notify "Dotfiles backup: rebase conflict needs manual fix"
                    return 1
                end
                __log "rebased onto origin/$branch"
            end
        end
    else
        __log "fetch from origin failed (offline?); committing locally only"
    end

    __push_to origin
    or begin
        __notify "Dotfiles backup: push to GitHub failed"
        return 1
    end

    # Codeberg mirror is best-effort.
    if git remote get-url codeberg >/dev/null 2>&1
        if git fetch --quiet codeberg $branch 2>/dev/null
            if not __push_to codeberg
                __log "codeberg mirror is behind; will retry next run"
            end
        else
            __log "codeberg fetch failed (non-fatal)"
        end
    end
    return 0
end

function __run
    cd $repo
    or begin
        __log "cannot cd to $repo"
        return 1
    end

    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        __log "$repo is not a git repository"
        return 1
    end

    __rotate_log
    __log "backup started"
    test $refresh_manifests -eq 1; and __refresh_manifests

    if not __commit_changes
        return 1
    end

    __sync_and_push
    set -l rc $status
    __log "backup finished (exit $rc)"
    return $rc
end

function __show_status
    cd $repo; or return 1
    git status --short --branch
    echo
    echo "backup log: $log_file"
    test -f $log_file; and tail -n 10 $log_file
end

# --------------------------------------------------------------- entrypoint
for arg in $argv
    switch $arg
        case -n --dry-run
            set dry_run 1
        case --no-manifests
            set refresh_manifests 0
        case status
            __show_status
            exit $status
        case log
            test -f $log_file; and tail -n 50 $log_file
            exit $status
        case -h --help
            echo "usage: autobackup.fish [--dry-run] [--no-manifests] [status|log]"
            exit 0
    end
end

mkdir -p (dirname $log_file)

if test $dry_run -eq 0
    __acquire_lock; or exit 0
end

__run
set -l rc $status
if test $dry_run -eq 0
    __release_lock
end
exit $rc