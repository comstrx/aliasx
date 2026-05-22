
pids () {

    local name="${1:-}" line="" pid="" owner="" args="" uid=""
    local -a cmd=()

    [[ -n "${name}" ]] || return 1
    uid="$(id -u 2>/dev/null || true)"

    if ps axo pid=,ppid=,uid=,args= >/dev/null 2>&1; then

        cmd=( ps axo 'pid=,ppid=,uid=,args=' )

    elif ps -eo pid=,ppid=,uid=,args= >/dev/null 2>&1; then

        cmd=( ps -eo 'pid=,ppid=,uid=,args=' )

    else

        command -v pgrep >/dev/null 2>&1 || return 0

        while IFS= read -r pid; do

            [[ "${pid}" =~ ^[0-9]+$ ]] || continue
            [[ "${pid}" == "$$" || "${pid}" == "${BASHPID:-}" || "${pid}" == "${PPID:-}" ]] && continue

            printf '%s\n' "${pid}"

        done < <(
            if [[ -n "${uid}" ]]; then pgrep -u "${uid}" -f -- "${name}" 2>/dev/null
            else pgrep -f -- "${name}" 2>/dev/null
            fi || true
        )

        return 0

    fi

    while IFS= read -r line || [[ -n "${line}" ]]; do

        read -r pid _ owner args <<< "${line}"

        [[ "${pid}" =~ ^[0-9]+$ ]] || continue
        [[ -z "${uid}" || "${owner}" == "${uid}" ]] || continue
        [[ "${args}" == *"${name}"* ]] || continue
        [[ "${pid}" == "$$" || "${pid}" == "${BASHPID:-}" || "${pid}" == "${PPID:-}" ]] && continue

        printf '%s\n' "${pid}"

    done < <("${cmd[@]}")

}
show () {

    local name="${1:-}" pid="" pid_csv=""
    local -a pids=()

    [[ -n "${name}" ]] || { err "Usage: show <process-name>"; return; }

    while IFS= read -r pid; do [[ -n "${pid}" ]] && pids+=( "${pid}" ); done < <(pids "${name}")
    [[ "${#pids[@]}" -gt 0 ]] || { warn "No process found: ${name}"; return; }

    pid_csv="$(IFS=,; printf '%s' "${pids[*]}")"

    ps -p "${pid_csv}" -o pid,ppid,user,%cpu,%mem,etime,stat,args 2>/dev/null \
        || ps -p "${pid_csv}" -o pid,ppid,user,stat,args

}
stop () {

    local name="${1:-}" pid=""
    local -a pids=() alive=() left=()

    [[ -n "${name}" ]] || { err "Usage: stop <process-name>"; return; }

    while IFS= read -r pid; do [[ -n "${pid}" ]] && pids+=( "${pid}" ); done < <(pids "${name}")
    [[ "${#pids[@]}" -gt 0 ]] || { warn "No process found: ${name}"; return; }

    kill -TERM "${pids[@]}" 2>/dev/null || true
    sleep 1

    for pid in "${pids[@]}"; do kill -0 "${pid}" 2>/dev/null && alive+=( "${pid}" ); done
    (( ${#alive[@]} == 0 )) || kill -KILL "${alive[@]}" 2>/dev/null || true

    for pid in "${pids[@]}"; do kill -0 "${pid}" 2>/dev/null && left+=( "${pid}" ); done
    (( ${#left[@]} == 0 )) || { err "Failed to stop: ${name}"; return; }

    succ "Stopped: ${name}"

}

copytext () {

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

url () {

    local raw="${1:-server}" key="" arg="" q="" ul="" own="" r=""

    [[ $# -gt 0 ]] && { shift 2>/dev/null || true; }

    arg="$*"
    q="${arg// /+}"
    key="$(lower "${raw}")"

    case "${key}" in
        http://*|https://*)
            ul="${raw}"
        ;;
        localhost)
            ul="http://localhost${arg:+:${arg}}"
        ;;
        127.0.0.1|0.0.0.0)
            ul="http://${key}${arg:+:${arg}}"
        ;;
        [0-9]*.[0-9]*.[0-9]*.[0-9]*)
            ul="http://${key}${arg:+:${arg}}"
        ;;
        localhost:*|127.*:*|0.0.0.0:*|[0-9]*.[0-9]*.[0-9]*.[0-9]*:*)
            ul="http://${raw}"
        ;;
        server|srv|api|backend)
            ul="http://127.0.0.1:${arg:-8000}"
        ;;
        front|client|web|app)
            ul="http://127.0.0.1:${arg:-3000}"
        ;;
        vite|react)
            ul="http://127.0.0.1:${arg:-5173}"
        ;;
        db|pma|phpmyadmin)
            ul="http://localhost${arg:+:${arg}}/phpmyadmin"
        ;;
        npm)
            ul="https://www.npmjs.com${arg:+/package/${arg#/}}"
        ;;
        crates|crate)
            ul="https://crates.io${arg:+/crates/${arg#/}}"
        ;;
        packagist|composer)
            ul="https://packagist.org${arg:+/packages/${arg#/}}"
        ;;
        gitlab|gl)
            ul="https://gitlab.com${arg:+/${arg#/}}"
        ;;
        github|gh)
            ul="https://github.com${arg:+/${arg#/}}"
        ;;
        repo)
            declare -F owner >/dev/null 2>&1 && own="$(owner 2>/dev/null || true)"
            [[ -n "${own}" ]] || own="${GITHUB_OWNER:-}"

            if [[ -z "${arg}" ]]; then ul="https://github.com/${own}"
            elif [[ "${arg}" == */* ]]; then ul="https://github.com/${arg#/}"
            else ul="https://github.com/${own}/${arg#/}"
            fi
        ;;
        release|releases)
            declare -F owner >/dev/null 2>&1 && own="$(owner 2>/dev/null || true)"
            [[ -n "${own}" ]] || own="${GITHUB_OWNER:-}"

            [[ -z "${arg}" ]] && declare -F repo >/dev/null 2>&1 && r="$(repo 2>/dev/null || true)"
            [[ -n "${r}" && -z "${arg}" ]] && arg="${r}"

            if [[ -z "${arg}" ]]; then ul="https://github.com/${own}"
            elif [[ "${arg}" == */* ]]; then ul="https://github.com/${arg#/}/releases"
            else ul="https://github.com/${own}/${arg#/}/releases"
            fi
        ;;
        aws)
            ul="https://console.aws.amazon.com${q:+/search?search=${q}}"
        ;;
        hostinger|hg)
            ul="https://hpanel.hostinger.com"
        ;;
        cloudflare|claudflare|cf)
            ul="https://dash.cloudflare.com"
        ;;
        azure)
            ul="https://portal.azure.com${q:+/#search/${q}}"
        ;;
        gcp|googlecloud|google-cloud|googleplatform|google-platform|gcloud)
            ul="https://console.cloud.google.com"
        ;;
        google)
            if [[ "$(lower "${arg}")" == "platform" || "$(lower "${arg}")" == "cloud" ]]; then ul="https://console.cloud.google.com"
            elif [[ -n "${arg}" ]]; then ul="https://www.google.com/search?q=${q}"
            else ul="https://www.google.com"
            fi
        ;;
        firebase)
            ul="https://console.firebase.google.com${arg:+/project/${arg#/}}"
        ;;
        jira)
            ul="${JIRA_URL:-https://jira.atlassian.com}"
            [[ -n "${arg}" ]] && ul="${ul%/}/browse/${arg}"
        ;;
        figma)
            if [[ -z "${arg}" ]]; then ul="https://www.figma.com/files"
            elif [[ "${arg}" == file/* || "${arg}" == design/* ]]; then ul="https://www.figma.com/${arg#/}"
            else ul="https://www.figma.com/design/${arg#/}"
            fi
        ;;
        whatsapp|wa)
            arg="${arg//[!0-9]/}"
            if [[ -n "${arg}" ]]; then ul="https://wa.me/${arg}"
            else ul="https://web.whatsapp.com"
            fi
        ;;
        telegram|tg)
            arg="${arg#@}"

            if [[ -n "${arg}" ]]; then ul="https://t.me/${arg#/}"
            else ul="https://web.telegram.org/k"
            fi
        ;;
        linkedin|in)
            case "${arg}" in
                "")         ul="https://www.linkedin.com" ;;
                company:*)  ul="https://www.linkedin.com/company/${arg#company:}" ;;
                in:*)       ul="https://www.linkedin.com/in/${arg#in:}" ;;
                */*)        ul="https://www.linkedin.com/${arg#/}" ;;
                *)          ul="https://www.linkedin.com/in/${arg}" ;;
            esac
        ;;
        */*)
            ul="https://github.com/${raw#/}"
        ;;
        *.*)
            ul="https://${raw}"
        ;;
        *)
            ul="https://www.${raw}.com"
        ;;
    esac

    ul="${ul/:80\//\/}"
    ul="${ul/:443\//\/}"
    ul="${ul%:80}"
    ul="${ul%:443}"

    out "${ul}"

}
openurl () {

    local ul=""

    ul="$(url "$@")" || return

    if command -v wslview >/dev/null 2>&1; then
        ( command wslview "${ul}" >/dev/null 2>&1 & )
        return 0
    fi
    if command -v cygstart >/dev/null 2>&1; then
        ( command cygstart "${ul}" >/dev/null 2>&1 & )
        return 0
    fi
    if command -v powershell.exe >/dev/null 2>&1; then
        ( command powershell.exe -NoProfile -NonInteractive -Command 'Start-Process -FilePath $args[0]' "${ul}" >/dev/null 2>&1 & )
        return 0
    fi
    if command -v cmd.exe >/dev/null 2>&1; then
        ( command cmd.exe /c start "" "${ul}" >/dev/null 2>&1 & )
        return 0
    fi
    if [[ -x /mnt/c/Windows/System32/cmd.exe ]]; then
        ( /mnt/c/Windows/System32/cmd.exe /c start "" "${ul}" >/dev/null 2>&1 & )
        return 0
    fi
    if command -v xdg-open >/dev/null 2>&1; then
        ( command xdg-open "${ul}" >/dev/null 2>&1 & )
        return 0
    fi
    if command -v open >/dev/null 2>&1; then
        ( command open "${ul}" >/dev/null 2>&1 & )
        return 0
    fi

    err "Failed to open: ${ul}"
    return

}
