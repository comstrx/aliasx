
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
