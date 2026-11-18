# agy (Antigravity CLI) quota in the prompt.
#
# `agy --prompt /usage` takes ~6s, so it never runs on a prompt redraw.
# scripts/agy-usage-refresh.fish refills a small cache file in the background
# and starship only reads that file.
#
# Do not background a fish function here: fish waits for function jobs when
# the enclosing block ends, which stalls the prompt for the full agy runtime.
# The refresh script is spawned as an external `fish <script>` process instead.

set -q AGY_USAGE_CACHE; or set -gx AGY_USAGE_CACHE $HOME/.cache/agy/usage
set -q AGY_USAGE_LOCK; or set -gx AGY_USAGE_LOCK $HOME/.cache/agy/usage.lock
set -q AGY_USAGE_MAX_AGE; or set -g AGY_USAGE_MAX_AGE 600   # seconds between refreshes
set -q AGY_USAGE_SCRIPT; or set -g AGY_USAGE_SCRIPT (dirname (status filename))/../scripts/agy-usage-refresh.fish

function __agy_usage_refresh --on-event fish_prompt --description "Refresh agy quota cache when stale"
    set -l now (date +%s)
    if test -s $AGY_USAGE_CACHE
        set -l age (math $now - (stat -f %m $AGY_USAGE_CACHE 2>/dev/null; or echo $now))
        test $age -lt $AGY_USAGE_MAX_AGE; and return
    end
    # One fetch at a time: another prompt may already be refreshing.
    if test -e $AGY_USAGE_LOCK
        set -l lock_age (math $now - (stat -f %m $AGY_USAGE_LOCK 2>/dev/null; or echo $now))
        test $lock_age -lt 90; and return
    end
    mkdir -p (dirname $AGY_USAGE_CACHE)
    touch $AGY_USAGE_LOCK
    fish $AGY_USAGE_SCRIPT >/dev/null 2>&1 &
    disown 2>/dev/null
end

# Warm the cache at shell start so the first prompt already has a value.
status is-interactive; and __agy_usage_refresh

function agy_usage --description "Show agy quota remaining (weekly / five-hour)"
    printf '%-18s %-24s %6s  %s\n' 'Group' 'Window' 'Left' 'Resets'
    for line in (agy --prompt /usage 2>/dev/null)
        set -l f (string split \t -- $line)
        test (count $f) -lt 4; and continue
        printf '%-18s %-24s %6s  %s\n' $f[1] $f[2] $f[3] $f[4]
    end
    rm -f $AGY_USAGE_LOCK
    fish $AGY_USAGE_SCRIPT >/dev/null 2>&1 &
    disown 2>/dev/null
end
