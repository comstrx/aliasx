
colored () {

    [[ -z "${NO_COLOR:-}" ]] || return 1
    [[ -n "${FORCE_COLOR:-}" || -n "${GITHUB_ACTIONS:-}" ]] && return 0
    [[ -n "${TERM:-}" ]] || return 1
    [[ "${TERM:-}" != "dumb" ]] || return 1
    [[ -t 1 || -t 2 ]]

}
out () {

    printf '%b\n' "$*"
    return 0

}
log () {

    printf '%b\n' "$*" >&2
    return 0

}
info () {

    if colored; then printf '\033[96m[*]\033[0m %b\n' "$*" >&2
    else printf '[*] %b\n' "$*" >&2
    fi

    return 0

}
succ () {

    if colored; then printf '\033[32m[+]\033[0m %b\n' "$*" >&2
    else printf '[+] %b\n' "$*" >&2
    fi

    return 0

}
warn () {

    if colored; then printf '\033[33m[!]\033[0m %b\n' "$*" >&2
    else printf '[!] %b\n' "$*" >&2
    fi

    return 0

}
err () {

    if colored; then printf '\033[31m[-]\033[0m %b\n' "$*" >&2
    else printf '[-] %b\n' "$*" >&2
    fi

    return 1

}
err_tmp () {

    local tmp="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${tmp}" ]] && { rm -f -- "${tmp}" 2>/dev/null || true; }
    (( $# > 0 )) && err "$@"

    return 1

}

bool () {

    local name="${1:-}" n=""
    shift >/dev/null 2>&1 || true

    case "${name,,}" in
        1|t|true|y|yes|on) return 0 ;;
    esac

    for n in "$@"; do

        [[ -n "${n}" ]] || continue
        case "${name,,}" in "${n,,}"|"-${n,,}"|"--${n,,}") return 0 ;;  esac

    done

    return 1

}
confirm () {

    local default="${1:-no}" msg="${2:-Are you sure}" answer="" hint=""

    [[ "${msg}" == *\? ]] || msg="${msg}?"

    case "${default,,}" in
        1|t|true|y|yes|on) hint="[Y/n]"; default="yes" ;;
        *)                 hint="[y/N]"; default="no"  ;;
    esac

    [[ ! -t 0 ]] && { [[ "${default}" == "yes" ]]; return; }
    read -r -p "${msg} ${hint} " answer

    case "${answer,,}" in
        "")                [[ "${default}" == "yes" ]] ;;
        1|t|true|y|yes|on) return 0 ;;
        *)                 return 1 ;;
    esac

}

assert_eq () {

    local actual="${1:-}" expected="${2:-}" message="${3:-}"
    [[ "${actual}" == "${expected}" ]] && return 0

    err "${message:-Assertion failed: expected [${expected}], got [${actual}]}"
    return 1

}
assert_ne () {

    local actual="${1:-}" expected="${2:-}" message="${3:-}"
    [[ "${actual}" != "${expected}" ]] && return 0

    err "${message:-Assertion failed: expected not [${expected}], got [${actual}]}"
    return 1

}
