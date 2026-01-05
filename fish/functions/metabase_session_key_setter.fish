# fish function to get a session key for Metabase
function metabase_session_key_setter
    set networks testnet mainnet

    set -l METABASE_URL ""
    set -l pass_path ""
    set -l connected false
    set -l metabase_network ""

    for network in $networks
        set pass_path metabase/$network
        pw url $pass_path
        set METABASE_URL (fish_clipboard_paste)

        if curl -s $METABASE_URL | grep -q Forbidden
        else
            set connected true
            set metabase_network $network
            break
        end
    end

    if not $connected
        echo "Not connected to a VPN"
        return
    end

    pw user $pass_path
    set -l METABASE_USER (fish_clipboard_paste)

    pw get $pass_path
    set -l METABASE_PASSWORD (fish_clipboard_paste)

    # Get the session key
    set response (curl -s -X POST -H "Content-Type: application/json" \
        -d "{\"username\": \"$METABASE_USER\", \"password\": \"$METABASE_PASSWORD\"}" \
        $METABASE_URL/api/session)

    # if Forbidden is in the string then don't set session_key
    if echo $response | grep -q Forbidden
        echo Forbidden
        return
    end

    set -l session_key (echo $response | jq -r '.id')

    set -gx METABASE_SESSION_KEY_$(echo $metabase_network | string upper) $session_key

    # clear clipboard
    echo "" | fish_clipboard_copy
end
