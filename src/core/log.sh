
clr () {

    [[ -z "${NO_COLOR:-}" ]]    || return 1
    [[ -n "${FORCE_COLOR:-}"    || -n "${GITHUB_ACTIONS:-}" ]] && return 0

    [[ -n "${TERM:-}" ]]        || return 1
    [[ "${TERM:-}" != "dumb" ]] || return 1

    [[ -t 1 || -t 2 ]]

}
lower () {

    local s="${1:-}"
    printf '%s' "${s,,}"

}
upper () {

    local s="${1:-}"
    printf '%s' "${s^^}"

}
cap () {

    local s="${1:-}"
    printf '%s' "${s^}"

}

out () {

    printf '%b\n' "$*"
    return 0

}
log () {

    printf '%b\n' "$*" >&2
    return 0

}
tint () {

    local code="${1:-}" tag="${2:-}"

    shift 2 >/dev/null 2>&1 || true

    if clr; then printf '\033[%sm%s\033[0m %b\n' "${code}" "${tag}" "$*" >&2
    else printf '%s %b\n' "${tag}" "$*" >&2
    fi

    return 0

}
info () {

    tint 96 '[*]' "$*"

}
succ () {

    tint 32 '[+]' "$*"

}
warn () {

    tint 33 '[!]' "$*"

}
err () {

    tint 31 '[-]' "$*"
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

    local name="${1:-}" n="" x=""

    name="$(lower "${name}")"
    shift >/dev/null 2>&1 || true

    case "${name}" in
        1|t|true|y|yes|on) return 0 ;;
    esac

    for n in "$@"; do

        [[ -n "${n}" ]] || continue

        x="$(lower "${n}")"
        case "${name}" in "${x}"|"-${x}"|"--${x}") return 0 ;; esac

    done

    return 1

}
confirm () {

    local default="${1:-no}" msg="${2:-Are you sure}" answer="" hint=""

    default="$(lower "${default}")"

    [[ "${msg}" == *\? ]] || msg="${msg}?"

    case "${default}" in
        1|t|true|y|yes|on) hint="[Y/n]"; default="yes" ;;
        *)                 hint="[y/N]"; default="no"  ;;
    esac

    [[ ! -t 0 ]] && { [[ "${default}" == "yes" ]]; return; }

    read -r -p "${msg} ${hint} " answer

    answer="$(lower "${answer}")"

    case "${answer}" in
        "")                [[ "${default}" == "yes" ]] ;;
        1|t|true|y|yes|on) return 0 ;;
        *)                 return 1 ;;
    esac

}

assert_eq () {

    local actual="${1:-}" expected="${2:-}" message="${3:-}"

    [[ "${actual}" == "${expected}" ]] && return 0

    err "${message:-Assertion failed: expected [${expected}], got [${actual}]}"
    return

}
assert_ne () {

    local actual="${1:-}" expected="${2:-}" message="${3:-}"

    [[ "${actual}" != "${expected}" ]] && return 0

    err "${message:-Assertion failed: expected not [${expected}], got [${actual}]}"
    return

}
