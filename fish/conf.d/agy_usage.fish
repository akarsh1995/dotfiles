# agy (Antigravity CLI) quota in the prompt.
#
# `agy --prompt /usage` takes ~6s, so it must never run on a prompt redraw.
# A background job refreshes a small cache file, and starship only reads it.

set -q AGY_USAGE_CACHE; or set -g AGY_USAGE_CACHE $HOME/.cache/agy/usage
set -q AGY_USAGE_MAX_AGE; or set -g AGY_USAGE_MAX_AGE 600   # seconds between refreshes
set -q AGY_USAGE_LOCK; or set -g AGY_USAGE_LOCK $HOME/.cache/agy/usage.lock
set -q AGY_USAGE_PINNED; or set -g AGY_USAGE_PINNED 0        # 1 = keep last value, refresh failed

function __agy_usage_shorten --description "Trim a percentage like 69.5% to 69%"
    string replace -r '\.\d+%$' '%' -- $argv[1]
end

function __agy_usage_fetch --description "Fetch agy quota and rewrite the cache file"
    set -l cache $AGY_USAGE_CACHE
    set -l tmp $cache.tmp
    set -l gem_week ''
    set -l gem_five ''
    set -l ant_week ''
    set -l ant_five ''

    set -l out (agy --prompt /usage 2>/dev/null)
    if test -z "$out"
        rm -f $AGY_USAGE_LOCK
        return 1
    end

    for line in $out
        set -l f (string split \t -- $line)
        test (count $f) -lt 4; and continue
        set -l pct (__agy_usage_shorten (string replace '%' '' -- $f[3]))
        if string match -q 'Gemini*' $f[1]
            if string match -q '*Weekly*' $f[2]
                set gem_week $pct
            else if string match -q '*Five Hour*' $f[2]
                set gem_five $pct
            end
        else if string match -q 'Claude and GPT*' $f[1]
            if string match -q '*Weekly*' $f[2]
                set ant_week $pct
            else if string match -q '*Five Hour*' $f[2]
                set ant_five $pct
            end
        end
    end

    if test -z "$gem_week$gem_five$ant_week$ant_five"
        rm -f $AGY_USAGE_LOCK
        return 1
    end

    # Cache is one rendered line so the prompt only has to cat it.
    set -l seg ''
    test -n "$gem_week$gem_five"; and set seg "$seg G $gem_week/$gem_five%"
    test -n "$ant_week$ant_five"; and set seg "$seg C $ant_week/$ant_five%"

    mkdir -p (dirname $cache)
    string trim -- $seg >$tmp; and mv -f $tmp $cache
    rm -f $AGY_USAGE_LOCK
end

function __agy_usage_refresh --on-event fish_prompt --description "Refresh agy quota cache when stale"
    set -l now (date +%s)
    if test -s $AGY_USAGE_CACHE
        set -l age (math $now - (stat -f %m $AGY_USAGE_CACHE 2>/dev/null; or echo $now))
        test $age -lt $AGY_USAGE_MAX_AGE; and return
    end
    if test -e $AGY_USAGE_LOCK
        set -l lock_age (math $now - (stat -f %m $AGY_USAGE_LOCK 2>/dev/null; or echo $now))
        test $lock_age -lt 90; and return
    end
    mkdir -p (dirname $AGY_USAGE_CACHE)
    touch $AGY_USAGE_LOCK
    __agy_usage_fetch >/dev/null 2>&1 &
    disown 2>/dev/null
end

# Warm the cache on shell start so the first prompt already has a value.
status is-interactive; and __agy_usage_refresh

function agy_usage --description "Show agy quota remaining (weekly / five-hour)"
    printf '%-18s %-24s %6s  %s\n' 'Group' 'Window' 'Left' 'Resets'
    for line in (agy --prompt /usage 2>/dev/null)
        set -l f (string split \t -- $line)
        test (count $f) -lt 4; and continue
        printf '%-18s %-24s %6s  %s\n' $f[1] $f[2] $f[3] $f[4]
    end
    __agy_usage_fetch >/dev/null 2>&1
end
