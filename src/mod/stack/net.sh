
goto () {

    local ul=""

    ul="$(url "$@")" || return
    openurl "${ul}"

}
health () {

    need curl || return

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

    need wrk || return

    local ul="${1:-}" dur="${2:-1s}" con="${3:-200}" tout="${4:-5s}" tds="${5:-}"

    [[ -n "${tds}" ]] || tds="$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || printf '1')"

    ul="$(url "${ul}")" || return
    wrk -t"${tds}" -c"${con}" -d"${dur}" --timeout "${tout}" --latency "${ul}"

}
weather () {

    need curl || return
    curl -s "wttr.in/$*"

}
