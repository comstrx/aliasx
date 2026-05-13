
url () {

    local ul="${1:-server}" port="${2:-}"

    case "${ul}" in
        localhost)
            ul="http://localhost"
            [[ -n "${port}" ]] && ul="${ul}:${port}"
        ;;
        127.0.0.1|0.0.0.0)
            ul="http://${ul}"
            [[ -n "${port}" ]] && ul="${ul}:${port}"
        ;;
        [0-9]*.[0-9]*.[0-9]*.[0-9]*)
            ul="http://${ul}"
            [[ -n "${port}" ]] && ul="${ul}:${port}"
        ;;
        http://*|https://*) ;;
        localhost:*) ul="http://${ul}" ;;
        127.*:*|0.0.0.0:*|[0-9]*.[0-9]*.[0-9]*.[0-9]*:*) ul="http://${ul}" ;;
        pma|phpmyadmin) ul="http://localhost/phpmyadmin" ;;
        server) ul="http://127.0.0.1:${port:-8000}" ;;
        front) ul="http://127.0.0.1:${port:-3000}" ;;
        *.*) ul="https://${ul}" ;;
        *) ul="https://www.${ul}.com" ;;
    esac

    ul="${ul/:80\//\/}"
    ul="${ul/:443\//\/}"
    ul="${ul%:80}"
    ul="${ul%:443}"

    out "${ul}"

}
goto () {

    local ul=""

    ul="$(url "$@")" || return
    openurl "${ul}"

}
health () {

    ensure curl || return

    local ul="" code=""

    ul="$(url "$@")" || return

    code="$(curl -L -s -o /dev/null -w '%{http_code}' --connect-timeout 3 --max-time 8 "${ul}" 2>/dev/null)" \
        || { err "Down: ${ul}"; return; }

    case "${code}" in
        2*|3*) succ "Up: ${ul} (${code})" ;;
        *)     err "Down: ${ul} (${code})"; return ;;
    esac

}
bench () {

    ensure wrk || return

    local ul="${1:-}" dur="${2:-1s}" con="${3:-200}" tout="${4:-5s}" tds="${5:-}"

    [[ -n "${tds}" ]] || tds="$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || printf '1')"

    ul="$(url "${ul}")" || return
    wrk -t"${tds}" -c"${con}" -d"${dur}" --timeout "${tout}" --latency "${ul}"

}
weather () {

    ensure curl || return
    curl -s "wttr.in/$*"

}
