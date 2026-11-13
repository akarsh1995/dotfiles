#!/usr/bin/env fish
# Entry point for the launchd cleanup agents.
#
# launchd's StartCalendarInterval can only express "every Monday", so the
# cadence guards live here:
#   caches -> every other Monday (even ISO week)
#   build  -> first Monday of the month
#
# Usage: cleanup-scheduled.fish caches|build

set -g log_file $HOME/.config/scripts/cleanup.log

function __log
    echo (date "+%Y-%m-%d %H:%M:%S")" | launchd | $argv[1] | "(date "+%A %d %b %Y") >>$log_file
end

switch "$argv[1]"
    case caches
        set -l week (date +%V)
        if test (math "$week % 2") -ne 0
            __log "caches skipped (ISO week $week is odd)"
            exit 0
        end
        __log "caches run (ISO week $week)"
        cleanup

    case build
        set -l day (math (date +%d))
        if test $day -gt 7
            __log "build skipped (day $day is not in the first week)"
            exit 0
        end
        __log "build run (first Monday, day $day)"
        cleanup --build

    case '*'
        echo "usage: cleanup-scheduled.fish caches|build" >&2
        exit 1
end
