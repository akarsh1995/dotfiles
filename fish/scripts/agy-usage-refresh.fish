#!/usr/bin/env fish
# Refresh the agy quota cache that the prompt reads.
#
# Runs standalone so the shell can background it as an external command:
# backgrounding a fish *function* makes fish wait for it, which stalls the
# prompt for as long as `agy --prompt /usage` takes (~6s).

set -q AGY_USAGE_CACHE; or set -g AGY_USAGE_CACHE $HOME/.cache/agy/usage
set -q AGY_USAGE_LOCK; or set -g AGY_USAGE_LOCK $HOME/.cache/agy/usage.lock

set -l cache $AGY_USAGE_CACHE
set -l tmp $cache.tmp

function __agy_shorten --description "Trim a percentage like 69.5% to 69%"
    string replace -r '\.\d+%$' '%' -- $argv[1]
end

set -l out (agy --prompt /usage 2>/dev/null)
if not set -q out[1]
    rm -f $AGY_USAGE_LOCK
    exit 1
end

set -l gem_week ''
set -l gem_five ''
set -l ant_week ''
set -l ant_five ''

for line in $out
    set -l f (string split \t -- $line)
    test (count $f) -lt 4; and continue
    set -l pct (__agy_shorten (string replace '%' '' -- $f[3]))
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
    exit 1
end

# Cache holds one rendered line: the prompt only has to cat it.
set -l seg ''
test -n "$gem_week$gem_five"; and set seg "$seg G $gem_week/$gem_five%"
test -n "$ant_week$ant_five"; and set seg "$seg C $ant_week/$ant_five%"

mkdir -p (dirname $cache)
string trim -- $seg >$tmp; and mv -f $tmp $cache
rm -f $AGY_USAGE_LOCK
