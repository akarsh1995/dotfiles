# Commands to run in interactive sessions can go here
# Find and source the correct brew shellenv based on OS
if command -v brew &>/dev/null
    brew shellenv fish | source
else if test -f /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv fish | source
else if test -f /usr/local/bin/brew
    /usr/local/bin/brew shellenv fish | source
else if test -f /home/linuxbrew/.linuxbrew/bin/brew
    /home/linuxbrew/.linuxbrew/bin/brew shellenv fish | source
end
