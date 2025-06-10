# Function to convert epoch timestamp to human readable datetime
function epoch_to_date
    # Check if argument is provided
    if test (count $argv) -lt 1
        echo "Usage: epoch_to_date TIMESTAMP [FORMAT]"
        echo ""
        echo "Convert epoch timestamp to human readable datetime."
        echo "Automatically detects seconds vs milliseconds."
        echo ""
        echo "Arguments:"
        echo "  TIMESTAMP    Epoch timestamp (seconds or milliseconds)"
        echo "  FORMAT       Optional date format (default: '%Y-%m-%d %H:%M:%S %Z')"
        echo ""
        echo "Examples:"
        echo "  epoch_to_date 1672531200        # 2023-01-01 00:00:00"
        echo "  epoch_to_date 1672531200000     # 2023-01-01 00:00:00 (milliseconds)"
        echo "  epoch_to_date 1672531200 '%c'   # Custom format"
        echo ""
        echo "Common format codes:"
        echo "  %Y  4-digit year    %m  month (01-12)    %d  day (01-31)"
        echo "  %H  hour (00-23)    %M  minute (00-59)   %S  second (00-61)"
        echo "  %Z  timezone        %c  complete date/time"
        return 1
    end
    
    set -l timestamp $argv[1]
    set -l format '%Y-%m-%d %H:%M:%S %Z'
    
    # Use custom format if provided
    if test (count $argv) -ge 2
        set format $argv[2]
    end
    
    # Validate that timestamp is numeric
    if not string match -qr '^[0-9]+$' $timestamp
        echo "Error: Timestamp must be numeric"
        return 1
    end
    
    # Determine if timestamp is in seconds or milliseconds
    # Timestamps with more than 10 digits are likely milliseconds
    set -l timestamp_length (string length $timestamp)
    set -l epoch_seconds $timestamp
    
    if test $timestamp_length -gt 10
        # Likely milliseconds - convert to seconds
        set epoch_seconds (math $timestamp / 1000)
        echo "Detected milliseconds timestamp"
    else
        # Likely seconds
        echo "Detected seconds timestamp"
    end
    
    # Additional validation: check if the resulting date is reasonable
    # Epoch time started 1970-01-01, and we don't expect timestamps too far in future
    set -l current_time (date +%s)
    set -l max_future_time (math $current_time + 31536000 \* 50) # 50 years from now
    
    if test $epoch_seconds -lt 0
        echo "Error: Timestamp cannot be negative"
        return 1
    end
    
    if test $epoch_seconds -gt $max_future_time
        echo "Warning: Timestamp seems to be very far in the future"
    end
    
    # Convert epoch to human readable format
    if command -sq gdate
        # Use GNU date if available (via brew install coreutils on macOS)
        set -l human_date (gdate -d "@$epoch_seconds" +"$format" 2>/dev/null)
    else
        # Use BSD date (default on macOS)
        set -l human_date (date -r $epoch_seconds +"$format" 2>/dev/null)
    end
    
    if test $status -ne 0
        echo "Error: Failed to convert timestamp. Please check if the timestamp is valid."
        return 1
    end
    
    # Display the results
    echo ""
    echo "Original timestamp: $timestamp"
    echo "Epoch seconds:      $epoch_seconds"
    echo "Human readable:     $human_date"
    echo ""
    
    # Show relative time if possible
    if command -sq gdate
        set -l relative_time (gdate -d "@$epoch_seconds" --iso-8601=seconds 2>/dev/null)
        if test $status -eq 0
            echo "ISO 8601 format:    $relative_time"
        end
    end
    
    # Calculate time difference from now
    set -l time_diff (math $current_time - $epoch_seconds)
    set -l abs_diff (math "abs($time_diff)")
    
    if test $time_diff -gt 0
        # Past time
        if test $abs_diff -lt 60
            echo "Relative time:      $abs_diff seconds ago"
        else if test $abs_diff -lt 3600
            set -l minutes (math "round($abs_diff / 60)")
            echo "Relative time:      $minutes minutes ago"
        else if test $abs_diff -lt 86400
            set -l hours (math "round($abs_diff / 3600)")
            echo "Relative time:      $hours hours ago"
        else
            set -l days (math "round($abs_diff / 86400)")
            echo "Relative time:      $days days ago"
        end
    else if test $time_diff -lt 0
        # Future time
        if test $abs_diff -lt 60
            echo "Relative time:      in $abs_diff seconds"
        else if test $abs_diff -lt 3600
            set -l minutes (math "round($abs_diff / 60)")
            echo "Relative time:      in $minutes minutes"
        else if test $abs_diff -lt 86400
            set -l hours (math "round($abs_diff / 3600)")
            echo "Relative time:      in $hours hours"
        else
            set -l days (math "round($abs_diff / 86400)")
            echo "Relative time:      in $days days"
        end
    else
        echo "Relative time:      now"
    end
end
