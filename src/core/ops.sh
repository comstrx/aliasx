
copyt () {

    local cmd=() stdin=0

    [[ "${1:-}" == "-" ]] && { stdin=1; shift 2>/dev/null || true; }

    if command -v clip.exe >/dev/null 2>&1; then cmd=( clip.exe )
    elif [[ -x /mnt/c/Windows/System32/clip.exe ]]; then cmd=( /mnt/c/Windows/System32/clip.exe )
    elif command -v pbcopy >/dev/null 2>&1; then cmd=( pbcopy )
    elif command -v wl-copy >/dev/null 2>&1; then cmd=( wl-copy )
    elif command -v xclip >/dev/null 2>&1; then cmd=( xclip -selection clipboard )
    elif command -v xsel >/dev/null 2>&1; then cmd=( xsel --clipboard --input )
    else
        if (( stdin )); then cat
        elif (( $# > 0 )); then printf '%s' "$*"
        else cat
        fi
        return 1
    fi

    if (( stdin )); then "${cmd[@]}"
    elif (( $# > 0 )); then printf '%s' "$*" | "${cmd[@]}"
    else "${cmd[@]}"
    fi || return 1

    succ "Copied"

}
lockscreen () {

    local cg="/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"

    if command -v rundll32.exe >/dev/null 2>&1; then
        command rundll32.exe user32.dll,LockWorkStation >/dev/null 2>&1 && return 0
    fi
    if [[ -x /mnt/c/Windows/System32/rundll32.exe ]]; then
        /mnt/c/Windows/System32/rundll32.exe user32.dll,LockWorkStation >/dev/null 2>&1 && return 0
    fi
    if [[ -x "${cg}" ]]; then
        "${cg}" -suspend >/dev/null 2>&1 && return 0
    fi

    command -v loginctl >/dev/null 2>&1 && command loginctl lock-session >/dev/null 2>&1 && return 0
    command -v xdg-screensaver >/dev/null 2>&1 && command xdg-screensaver lock >/dev/null 2>&1 && return 0
    command -v dbus-send >/dev/null 2>&1 && command dbus-send --session --dest=org.freedesktop.ScreenSaver --type=method_call /ScreenSaver org.freedesktop.ScreenSaver.Lock >/dev/null 2>&1 && return 0
    command -v qdbus6 >/dev/null 2>&1 && command qdbus6 org.freedesktop.ScreenSaver /ScreenSaver Lock >/dev/null 2>&1 && return 0
    command -v qdbus >/dev/null 2>&1 && command qdbus org.freedesktop.ScreenSaver /ScreenSaver Lock >/dev/null 2>&1 && return 0
    command -v gnome-screensaver-command >/dev/null 2>&1 && command gnome-screensaver-command -l >/dev/null 2>&1 && return 0
    command -v cinnamon-screensaver-command >/dev/null 2>&1 && command cinnamon-screensaver-command --lock >/dev/null 2>&1 && return 0
    command -v mate-screensaver-command >/dev/null 2>&1 && command mate-screensaver-command --lock >/dev/null 2>&1 && return 0
    command -v xfce4-screensaver-command >/dev/null 2>&1 && command xfce4-screensaver-command --lock >/dev/null 2>&1 && return 0
    command -v xscreensaver-command >/dev/null 2>&1 && command xscreensaver-command -lock >/dev/null 2>&1 && return 0
    command -v dm-tool >/dev/null 2>&1 && command dm-tool lock >/dev/null 2>&1 && return 0

    err "No supported screen locker found"
    return

}
