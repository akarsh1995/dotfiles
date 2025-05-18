# Initialize the password store at startup

# This file just ensures the password store directory exists
# It doesn't load passwords into the environment like secrets do
if not test -d $XDG_CONFIG_HOME/fish/secure/passwords
    mkdir -p $XDG_CONFIG_HOME/fish/secure/passwords
end
