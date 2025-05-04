# 1. **Purpose of the File**:
#    - The file is used to set environment variables specific to the AYR project.
#    - These variables might include paths, API keys, or other configuration settings required for the project to function correctly.
#
# 2. **Usage of Variables**:
#    - The variables defined in this file can be used by scripts, commands, or other processes that rely on the AYR project configuration.
#
# 3. **Relevant Flags**:
#    - **`-gx` (Global Export)**:
#      - Use this flag when you want the variable to be available globally across all Fish shell sessions and sub-processes.
#      - Example: `set -gx VAR_NAME value`
#      - Use case: When the variable needs to be accessed by all scripts or commands, even outside the current shell session.
#    - **`-x` (Local Export)**:
#      - Use this flag when you want the variable to be exported only for the current shell session and its sub-processes.
#      - Example: `set -x VAR_NAME value`
#      - Use case: When the variable is only needed temporarily or for the current session.
#
# ### Example of Usage:
# ```fish
# # Global export: Makes the variable available globally
# set -gx PROJECT_PATH /path/to/ayr/project
#
# # Local export: Makes the variable available only in the current session
# set -x TEMP_API_KEY abc123
# ```

# set XDG Base Directory Specification - there could be a better way to do this
set -gx XDG_CACHE_HOME $HOME/.cache
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_DESKTOP_DIR $HOME/Desktop
set -gx XDG_DOWNLOAD_DIR $HOME/Downloads
set -gx XDG_DOCUMENTS_DIR $HOME/Documents
set -gx XDG_MUSIC_DIR $HOME/Music
set -gx XDG_PICTURES_DIR $HOME/Pictures
set -gx XDG_VIDEOS_DIR $HOME/Videos

set -gx EDITOR nvim

set -l plugins \
    'f:finder' \
    'o:fzopen' \
    'p:preview-tabbed' \
    'd:diffs' \
    't:nmount' \
    'v:imgview'

set -gx NNN_PLUG (string join ';' $plugins)
set -gx GPG_TTY (tty)
set -gx PASSWORD_STORE_ENABLE_EXTENSIONS true
set -gx PASSWORD_STORE_DIR $HOME/.config/pass
