function clean-npm-cache --description="Clean npm cache directory"
    set cache_dir "$HOME/.npm"
    if test -d "$cache_dir"
        rm -rf "$cache_dir"
        echo "npm cache cleaned: $cache_dir"
    else
        echo "npm cache directory not found: $cache_dir"
    end
end
