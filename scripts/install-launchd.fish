#!/usr/bin/env fish
# Install the scheduled agents that keep the dotfiles repo backed up and the
# machine tidy.
#
#   install-launchd.fish            # all
#   install-launchd.fish autobackup # hourly git backup only
#   install-launchd.fish cleanup    # weekly cache/build cleanup (macOS)
#
# macOS uses launchd so missed runs fire when the machine wakes. Linux uses a
# systemd user timer with Persistent=true for the same reason.

set -g fish_bin (command -s fish 2>/dev/null)
test -n "$fish_bin"; or set fish_bin (status fish-path 2>/dev/null)
set -g repo $HOME/.config
set -g backup_script $repo/scripts/autobackup.fish
set -g cleanup_script $repo/scripts/cleanup-scheduled.fish

function __which --argument-names target
    switch $target
        case autobackup cleanup all
            echo $target
        case '*'
            echo "usage: install-launchd.fish [autobackup|cleanup|all]" >&2
            return 1
    end
end

function __install_plist --argument-names label content
    set -l dir $HOME/Library/LaunchAgents
    set -l path $dir/$label.plist
    mkdir -p $dir
    printf '%s\n' $content >$path
    launchctl bootout gui/(id -u)/$label >/dev/null 2>&1
    if launchctl bootstrap gui/(id -u) $path
        echo "installed $label"
    else
        echo "warning: could not load $label (plist kept at $path)" >&2
    end
end

function __autobackup_plist
    set -l template '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.akarsh.autobackup</string>
    <key>ProgramArguments</key>
    <array>
        <string>__FISH__</string>
        <string>__SCRIPT__</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Minute</key><integer>0</integer>
    </dict>
    <key>RunAtLoad</key><true/>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
    <key>StandardOutPath</key><string>__LOG__</string>
    <key>StandardErrorPath</key><string>__LOG__</string>
    <key>ProcessType</key><string>Background</string>
    <key>LowPriorityIO</key><true/>
    <key>Nice</key><integer>10</integer>
</dict>
</plist>'
    string replace -a __FISH__ $fish_bin $template |
        string replace -a __SCRIPT__ $backup_script |
        string replace -a __LOG__ $repo/scripts/launchd.autobackup.log
end

function __cleanup_plist --argument-names entry hour minute
    set -l template '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.akarsh.cleanup.__ENTRY__</string>
    <key>ProgramArguments</key>
    <array>
        <string>__FISH__</string>
        <string>__SCRIPT__</string>
        <string>__ENTRY__</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key><integer>1</integer>
        <key>Hour</key><integer>__HOUR__</integer>
        <key>Minute</key><integer>__MINUTE__</integer>
    </dict>
    <key>StandardOutPath</key><string>__LOG__</string>
    <key>StandardErrorPath</key><string>__LOG__</string>
    <key>ProcessType</key><string>Background</string>
    <key>LowPriorityIO</key><true/>
</dict>
</plist>'
    string replace -a __FISH__ $fish_bin $template |
        string replace -a __SCRIPT__ $cleanup_script |
        string replace -a __ENTRY__ $entry |
        string replace -a __HOUR__ $hour |
        string replace -a __MINUTE__ $minute |
        string replace -a __LOG__ $repo/scripts/launchd.cleanup.log
end

function __install_launchd --argument-names target
    if test $target = autobackup; or test $target = all
        __install_plist com.akarsh.autobackup (__autobackup_plist)
    end
    if test $target = cleanup; or test $target = all
        if not test -f $cleanup_script
            echo "warning: $cleanup_script missing; skipping cleanup agents" >&2
        else
            __install_plist com.akarsh.cleanup.caches (__cleanup_plist caches 12 0)
            __install_plist com.akarsh.cleanup.build (__cleanup_plist build 12 30)
        end
    end
end

function __install_systemd --argument-names target
    if test $target = cleanup
        echo "cleanup agent is macOS-only; skipping on Linux" >&2
        return 0
    end

    set -l unit_dir $HOME/.config/systemd/user
    mkdir -p $unit_dir

    printf '%s\n' '[Unit]' \
        'Description=Dotfiles auto backup' \
        '' \
        '[Service]' \
        'Type=oneshot' \
        "ExecStart=$fish_bin $backup_script" \
        >$unit_dir/dotfiles-autobackup.service

    printf '%s\n' '[Unit]' \
        'Description=Hourly dotfiles auto backup' \
        '' \
        '[Timer]' \
        'OnCalendar=hourly' \
        'Persistent=true' \
        'RandomizedDelaySec=120' \
        '' \
        '[Install]' \
        'WantedBy=timers.target' \
        >$unit_dir/dotfiles-autobackup.timer

    if command -q systemctl
        systemctl --user daemon-reload
        and systemctl --user enable --now dotfiles-autobackup.timer
        and echo "installed dotfiles-autobackup.timer"
    else
        echo "warning: systemctl not found; units written to $unit_dir" >&2
    end
end

set -l target all
if test (count $argv) -gt 0
    set target (__which $argv[1]); or exit 1
end

switch (uname -s)
    case Darwin
        __install_launchd $target
    case Linux
        __install_systemd $target
    case '*'
        echo "unsupported OS: "(uname -s) >&2
        exit 1
end