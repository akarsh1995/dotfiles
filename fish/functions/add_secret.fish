# a function that adds a secret to the secrets file
function add_secret
    # check if the first argument is empty
    if test -z "$argv[1]"
        echo "Please provide a secret name"
        return 1
    end

    # check if the second argument is empty
    if test -z "$argv[2]"
        echo "Please provide a secret value"
        return 1
    end

    # Check if secret already exists
    if grep -q "^set -gx $argv[1] " $SECRET_VARS_PATH
        # Get existing comment if any
        set -l existing_comment (grep "^set -gx $argv[1] " $SECRET_VARS_PATH | grep -o "#.*\$" || echo "")

        # Replace the existing secret
        if test (count $argv) -eq 2
            # Keep existing comment if there is one
            if test -n "$existing_comment"
                sed -i "" "s|^set -gx $argv[1] .*|set -gx $argv[1] \"$argv[2]\" $existing_comment|" $SECRET_VARS_PATH
            else
                sed -i "" "s|^set -gx $argv[1] .*|set -gx $argv[1] \"$argv[2]\"|" $SECRET_VARS_PATH
            end
        else
            # Use new comment
            sed -i "" "s|^set -gx $argv[1] .*|set -gx $argv[1] \"$argv[2]\" # $argv[3]|" $SECRET_VARS_PATH
        end

        # Update the variable in the current environment
        set -gx $argv[1] $argv[2]

        echo "Secret updated"
        return 0
    else
        # Check if description is provided for new secret
        if test (count $argv) -lt 3 -o -z "$argv[3]"
            echo "Please provide a description when adding a new secret"
            return 1
        end

        # Add the secret with description
        echo "set -gx $argv[1] \"$argv[2]\" # $argv[3]" >>$SECRET_VARS_PATH

        # Set the variable in the current environment
        set -gx $argv[1] $argv[2]

        echo "Secret added"
    end
end
