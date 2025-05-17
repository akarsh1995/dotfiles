# a function that gives a meaningful commit message and commits and push to the main
# config_auto_commit_and_push

function config_auto_commit_and_push
    cd $HOME/.config

    # check if the current directory is a git repository
    if not git rev-parse --is-inside-work-tree > /dev/null 2>&1
        echo "Not a git repository"
        return 1
    end

    # check if there are any changes to commit
    if not git diff-index --quiet HEAD --
        # get the current date and time
        set now (date "+%Y-%m-%d %H:%M:%S")
        # get the current branch name
        set branch (git rev-parse --abbrev-ref HEAD)
        # commit the changes with a meaningful message
        git add .
        git commit -m "Auto commit on $now on branch $branch"
        # push the changes to the remote repository
        git push origin $branch
    else
        echo "No changes to commit"
    end
end