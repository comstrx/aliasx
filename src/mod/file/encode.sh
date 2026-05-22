
encode () {

    need base64 || return 1

    [[ "$#" -gt 0 ]] || { err "Missing text"; return 1; }
    printf '%s' "$*" | base64 | tr -d '\n' | copyt -

}
decode () {

    need base64 || return 1
    [[ "$#" -gt 0 ]] || { err "Missing base64 text"; return 1; }

    if base64 --help 2>&1 | grep -q -- '--decode'; then printf '%s' "$*" | base64 --decode | copyt -
    else printf '%s' "$*" | base64 -D | copyt -
    fi

}
encodefile () {

    need base64 || return 1

    local file="${1:-}" dest="${2:-}"
    [[ -n "${file}" && -f "${file}" ]] || { err "Missing file: ${file}"; return 1; }

    if [[ -n "${dest}" ]]; then
        base64 -w 0 "${file}" > "${dest}" || { err "Failed to encode: ${file}"; return 1; }
        succ "Encoded: ${dest}"
    else
        base64 -w 0 "${file}" | copyt
    fi

}
decodefile () {

    need base64 || return 1

    local src="${1:-}" dst="${2:-}"
    [[ -n "${src}" && -f "${src}" ]] || { err "Missing file: ${src}"; return 1; }

    if [[ -n "${dst}" ]]; then
        base64 -d "${src}" > "${dst}" || { err "Failed to decode: ${src}"; return 1; }
        succ "Decoded: ${dst}"
    else
        base64 -d "${src}" | copyt
    fi

}
