#!/usr/bin/env fish
# Keep fisher-managed files out of git without committing per-file rules.
#
# Fisher records ownership in the universal variable
# `_fisher_<escaped-plugin>_files`, which lists every file a plugin installed.
# This script turns that manifest into a managed block in .git/info/exclude, so
# plugin files (including ones a plugin adds later) are excluded automatically
# and the repo never has to guess filenames.
#
#   sync-fisher-ignores.fish            # rewrite the block
#   sync-fisher-ignores.fish --dry-run  # print the block, change nothing
#   sync-fisher-ignores.fish --check    # exit 1 if the block is stale
#
# .git/info/exclude is local to this clone, which is why the paths are not
# committed. The naming conventions in .gitignore remain as a backstop for
# plugins whose manifest is missing.

set -g dry_run 0
set -g check_only 0

for arg in $argv
    switch $arg
        case -n --dry-run
            set dry_run 1
        case -c --check
            set check_only 1
            set dry_run 1
        case -h --help
            echo "usage: sync-fisher-ignores.fish [--dry-run|--check]"
            exit 0
        case '*'
            echo "sync-fisher-ignores.fish: unknown option '$arg'" >&2
            exit 1
    end
end

set -l begin_marker '# >>> fisher plugin files (managed by scripts/sync-fisher-ignores.fish)'
set -l end_marker '# <<< fisher plugin files'

# Resolve the repo root from the script location. `status dirname` is relative
# to the caller's cwd, so resolve it before walking up.
set -l here (status dirname)
test "$here" = "Standard input"; and set here $HOME/.config/scripts
set -g repo (path resolve $here/..)

set -l exclude_file (git -C $repo rev-parse --git-path info/exclude 2>/dev/null)
if test -z "$exclude_file"
    set exclude_file $repo/.git/info/exclude
else
    string match -q '/*' -- $exclude_file; or set exclude_file $repo/$exclude_file
    set exclude_file (path normalize $exclude_file)
end

# Every file fisher says it installed, as a path relative to the repo root.
# Values may be stored with a literal ~ instead of $HOME.
function __owned_paths --argument-names repo
    set -l paths
    for var in (set --names --universal | string match -r '^_fisher_.*_files$')
        for raw in $$var
            set -l path (string replace -- '~' $HOME $raw)
            test -d $path; and continue
            if string match -q "$repo/*" -- $path
                set paths $paths (string replace -- "$repo/" '' $path)
            end
        end
    end
    printf '%s\n' $paths | sort -u
end

function __plugin_count
    count (set --names --universal | string match -r '^_fisher_.*_files$')
end

set -l owned (__owned_paths $repo)

# Build the block that should exist.
set -l block
set block $block $begin_marker
set block $block '# Generated from fisher universal variables. Do not edit by hand.'
if test (count $owned) -gt 0
    set block $block $owned
else
    set block $block '# (no fisher plugins installed yet)'
end
set block $block $end_marker

# Rebuild the file: everything outside the markers, trailing blank lines
# trimmed, then one blank line and the managed block.
set -l tmp (mktemp)
if test -f $exclude_file
    sed "/^# >>> fisher plugin files/,/^# <<< fisher plugin files/d" $exclude_file \
        | awk 'NF { last = NR } { line[NR] = $0 } END { for (i = 1; i <= last; i++) print line[i] }' \
        >$tmp
else
    true >$tmp
end
test -s $tmp; and echo >>$tmp
printf '%s\n' $block >>$tmp

set -l up_to_date 0
if test -f $exclude_file; and cmp -s $tmp $exclude_file
    set up_to_date 1
end

if test $check_only -eq 1
    if test $up_to_date -eq 1
        echo "fisher excludes: up to date ("(count $owned)" file(s), "(__plugin_count)" plugin(s))"
        rm -f $tmp
        exit 0
    end
    echo "fisher excludes: stale - run scripts/sync-fisher-ignores.fish" >&2
    rm -f $tmp
    exit 1
end

if test $dry_run -eq 1
    echo "# would write $exclude_file"
    printf '%s\n' $block
    rm -f $tmp
    exit 0
end

mkdir -p (dirname $exclude_file)
cat $tmp >$exclude_file
rm -f $tmp
echo "fisher excludes: "(count $owned)" file(s) from "(__plugin_count)" plugin(s)"
