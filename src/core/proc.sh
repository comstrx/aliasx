
has () {

    [[ -n "${1:-}" ]] || { err "Missing binary name"; return 1; }

    command -v "${1}" >/dev/null 2>&1

}
need () {

    has "${1:-}" || { err "Missing: ${1:-}"; return 1; }

}

run_ok () {

    [[ "$#" -gt 0 ]] || return 0
    "$@" >/dev/null 2>&1 || return 1
    return 0

}

ensure () {

    local bin="${1:-}"
    local package="${2:-${bin}}"

    [[ -n "${bin}" ]] || { err "Missing binary name"; return 1; }

    if ! command -v "${bin}" >/dev/null 2>&1; then
        sudo apt-get update -qq || { err "Failed to update apt"; return 1; }
        sudo apt-get install -y --no-install-recommends "${package}" || { err "Failed to install: ${package}"; return 1; }
    fi

}
ensure_ok () {

    ensure "$@" >/dev/null 2>&1 || return 1
    return 0

}

show () {

    local name="${1:-}" pid_csv=""

    [[ -n "${name}" ]] || { err "Usage: show <process-name>"; return 1; }

    pid_csv="$(pgrep -u "${USER}" -f -- "${name}" | grep -v -x -- "$$" | paste -sd, -)"
    [[ -n "${pid_csv}" ]] || { warn "No process found: ${name}"; return 1; }

    ps -p "${pid_csv}" -o pid,ppid,user,%cpu,%mem,etime,stat,args

}
stop () {

    local name="${1:-}" pid=""
    local -a pids=()

    [[ -n "${name}" ]] || { err "Usage: stop <process-name>"; return 1; }

    while IFS= read -r pid; do
        [[ "${pid}" == "$$" ]] && continue
        pids+=( "${pid}" )
    done < <(pgrep -u "${USER}" -f -- "${name}")

    [[ "${#pids[@]}" -gt 0 ]] || { warn "No process found: ${name}"; return 1; }

    kill "${pids[@]}" 2>/dev/null || true
    sleep 1

    kill -0 "${pids[@]}" 2>/dev/null && { kill -9 "${pids[@]}" 2>/dev/null || true; }
    succ "Stopped: ${name}"

}

lock () {

    if [[ -r /proc/version ]] && grep -qiE 'microsoft|wsl' /proc/version; then

        [[ -x /mnt/c/Windows/System32/rundll32.exe ]] || { err "Windows lock command not found"; return 1; }

        /mnt/c/Windows/System32/rundll32.exe user32.dll,LockWorkStation >/dev/null 2>&1
        return $?

    fi

    command -v loginctl >/dev/null 2>&1 && loginctl lock-session >/dev/null 2>&1 && return 0
    command -v xdg-screensaver >/dev/null 2>&1 && xdg-screensaver lock >/dev/null 2>&1 && return 0
    command -v gnome-screensaver-command >/dev/null 2>&1 && gnome-screensaver-command -l >/dev/null 2>&1 && return 0
    command -v qdbus >/dev/null 2>&1 && qdbus org.freedesktop.ScreenSaver /ScreenSaver Lock >/dev/null 2>&1 && return 0
    command -v dm-tool >/dev/null 2>&1 && dm-tool lock >/dev/null 2>&1 && return 0
    command -v cinnamon-screensaver-command >/dev/null 2>&1 && cinnamon-screensaver-command --lock >/dev/null 2>&1 && return 0
    command -v mate-screensaver-command >/dev/null 2>&1 && mate-screensaver-command --lock >/dev/null 2>&1 && return 0
    command -v xscreensaver-command >/dev/null 2>&1 && xscreensaver-command -lock >/dev/null 2>&1 && return 0

    err "No supported screen locker found"
    return 1

}
copy () {

    local cmd=() stdin=0

    [[ "${1:-}" == "-" ]] && { stdin=1; shift 2>/dev/null || true; }

    if has clip.exe; then cmd=( clip.exe )
    elif [[ -x /mnt/c/Windows/System32/clip.exe ]]; then cmd=( /mnt/c/Windows/System32/clip.exe )
    elif has pbcopy; then cmd=( pbcopy )
    elif has wl-copy; then cmd=( wl-copy )
    elif has xclip; then cmd=( xclip -selection clipboard )
    elif has xsel; then cmd=( xsel --clipboard --input )
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
openurl () {

    local url="${1:-}"
    [[ -n "${url}" ]] || { err "Missing url"; return 1; }

    if [[ -r /proc/version ]] && grep -qiE 'microsoft|wsl' /proc/version; then

        if command -v wslview >/dev/null 2>&1; then
            ( nohup wslview "${url}" >/dev/null 2>&1 & )
            return 0
        fi
        if [[ -x /mnt/c/Windows/System32/cmd.exe ]]; then
            ( nohup /mnt/c/Windows/System32/cmd.exe /c start "" "${url}" >/dev/null 2>&1 & )
            return 0
        fi

    fi
    if command -v xdg-open >/dev/null 2>&1; then
        ( nohup xdg-open "${url}" >/dev/null 2>&1 & )
        return 0
    fi
    if command -v open >/dev/null 2>&1; then
        ( nohup open "${url}" >/dev/null 2>&1 & )
        return 0
    fi

    err "Failed to open: ${url}"
    return 1

}
