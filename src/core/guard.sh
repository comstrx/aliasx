
bash-version () {

    local v="${BASH_VERSION:-}"

    [[ -n "${v}" ]] || return 1
    printf '%s\n' "${v}"

}
bash-major () {

    local v="${BASH_VERSINFO[0]:-}"

    [[ "${v}" =~ ^[0-9]+$ ]] || return 1
    printf '%s\n' "${v}"

}
bash-minor () {

    local v="${BASH_VERSINFO[1]:-}"

    [[ "${v}" =~ ^[0-9]+$ ]] || return 1
    printf '%s\n' "${v}"

}
bash-msrv () {

    local need="${1:-}" cur="${2:-${BASH_VERSION:-}}" n1=0 n2=0 n3=0 c1=0 c2=0 c3=0

    [[ "${need}" =~ ^[0-9]+([.][0-9]+){0,2}$ ]] || return 1
    [[ "${cur}" =~ ^([0-9]+)([.]([0-9]+))?([.]([0-9]+))? ]] || return 1

    IFS=. read -r n1 n2 n3 <<< "${need}"

    c1="${BASH_REMATCH[1]:-0}"; c2="${BASH_REMATCH[3]:-0}"; c3="${BASH_REMATCH[5]:-0}"
    n1="${n1:-0}"; n2="${n2:-0}"; n3="${n3:-0}"
    c1="${c1:-0}"; c2="${c2:-0}"; c3="${c3:-0}"

    (( c1 > n1 )) && return 0
    (( c1 < n1 )) && return 1
    (( c2 > n2 )) && return 0
    (( c2 < n2 )) && return 1

    (( c3 >= n3 ))

}
bash-ok () {

    local bin="${1:-}" need="${2:-}" cur=""

    [[ -n "${bin}" && -n "${need}" ]] || return 1

    command -v -- "${bin}" >/dev/null 2>&1 && bin="$(command -v -- "${bin}" 2>/dev/null || true)"
    [[ -x "${bin}" ]] || return 1

    # shellcheck disable=SC2016
    cur="$("${bin}" -c 'printf "%s\n" "${BASH_VERSION:-}"' 2>/dev/null || true)"

    bash-msrv "${need}" "${cur}"

}
bash-path () {

    local need="${1:-}" bin="" resolved=""

    [[ "${need}" =~ ^[0-9]+([.][0-9]+){0,2}$ ]] || return 1

    for bin in \
        "${BASHX_BASH:-}" \
        bash \
        /opt/homebrew/bin/bash \
        /usr/local/bin/bash \
        /usr/bin/bash \
        /bin/bash \
        /mingw64/bin/bash.exe \
        /usr/bin/bash.exe \
        /c/Program\ Files/Git/bin/bash.exe \
        /c/Program\ Files/Git/usr/bin/bash.exe
    do

        [[ -n "${bin}" ]] || continue

        if command -v -- "${bin}" >/dev/null 2>&1; then resolved="$(command -v -- "${bin}" 2>/dev/null || true)"
        else resolved="${bin}"
        fi

        bash-ok "${resolved}" "${need}" || continue
        printf '%s\n' "${resolved}"

        return 0

    done

    return 1

}
ensure-bash () {

    local need="${1:-}" found="" script=""

    if [[ "${need}" =~ ^[0-9]+([.][0-9]+){0,2}$ ]]; then shift || true
    else need="${MIN_BASH_VERSION:-${MSRV_BASH_VERSION:-${MSRV_VERSION:-5}}}"
    fi

    [[ "${need}" =~ ^[0-9]+([.][0-9]+){0,2}$ ]] || return 1
    bash-msrv "${need}" && { export ENSURE_MIN_BASH_VERSION_DONE=1; return 0; }

    [[ "${ENSURE_MIN_BASH_VERSION_DONE:-}" == "1" ]] && return 1
    [[ "${BASH_SOURCE[0]}" == "$0" ]] || return 1

    found="$(bash-path "${need}" 2>/dev/null || true)"

    if [[ -z "${found}" ]]; then

        install-bin bash || return 1
        hash -r 2>/dev/null || true
        found="$(bash-path "${need}" 2>/dev/null || true)"

    fi

    [[ -n "${found}" ]] || return 1

    script="${0:-}"
    [[ -z "${script}" || ! -f "${script}" ]] && script="${BASH_SOURCE[0]:-${0:-}}"
    [[ -n "${script}" && -f "${script}" ]] || return 1

    ENSURE_MIN_BASH_VERSION_DONE=1 exec "${found}" "${script}" "$@"

}
