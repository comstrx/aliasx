
encode () {

    ensure base64 || return 1

    [[ "$#" -gt 0 ]] || { err "Missing text"; return 1; }
    printf '%s' "$*" | base64 | tr -d '\n' | copytext -

}
decode () {

    ensure base64 || return 1

    [[ "$#" -gt 0 ]] || { err "Missing base64 text"; return 1; }

    if base64 --help 2>&1 | grep -q -- '--decode'; then printf '%s' "$*" | base64 --decode | copytext -
    else printf '%s' "$*" | base64 -D | copytext -
    fi

}

encodefile () {

    ensure base64 coreutils || return 1

    local file="${1:-}" dest="${2:-}"

    [[ -n "${file}" && -f "${file}" ]] || { err "Missing file: ${file}"; return 1; }

    if [[ -n "${dest}" ]]; then
        base64 -w 0 "${file}" > "${dest}" || { err "Failed to encode: ${file}"; return 1; }
        succ "Encoded: ${dest}"
    else
        base64 -w 0 "${file}" | copytext
    fi

}
decodefile () {

    ensure base64 coreutils || return 1

    local src="${1:-}" dst="${2:-}"

    [[ -n "${src}" && -f "${src}" ]] || { err "Missing file: ${src}"; return 1; }

    if [[ -n "${dst}" ]]; then
        base64 -d "${src}" > "${dst}" || { err "Failed to decode: ${src}"; return 1; }
        succ "Decoded: ${dst}"
    else
        base64 -d "${src}" | copytext
    fi

}

envfile () {

    local mode="${1:-}" file="${2:-}" type="${3:-env}" root="" f="" t=""
    local -a list=() types=()

    root="$(git rev-parse --show-toplevel 2>/dev/null || printf '%s' "${PWD:-.}")"
    [[ -n "${file}" && ! -f "${file}" && -f "${root}/${file}" ]] && file="${root}/${file}"

    case "${mode}" in
        pro*) list=( production prod pro "" ) ;;
        st*)  list=( st sta stag stage "" pro prod production ) ;;
        *)    list=( "" local dev st sta stag stage pro prod production ) ;;
    esac
    case "${type}" in
        sec*) types=( secrets secret sec ) ;;
        var*) types=( vars var variables variable ) ;;
        *)    types=( env envs vars var variables variable secrets secret sec ) ;;
    esac

    if [[ ! -f "${file}" ]]; then

        for t in "${types[@]}"; do

            for f in "${list[@]}"; do

                if [[ -z "${f}" ]]; then
                    [[ -f "${root}/.${t}" ]] && { file="${root}/.${t}"; break 2; }
                    [[ -f "${root}/${t}"  ]] && { file="${root}/${t}";  break 2; }
                else
                    [[ -f "${root}/.${t}.${f}" ]] && { file="${root}/.${t}.${f}"; break 2; }
                    [[ -f "${root}/${t}.${f}"  ]] && { file="${root}/${t}.${f}";  break 2; }
                    [[ -f "${root}/.${f}.${t}" ]] && { file="${root}/.${f}.${t}"; break 2; }
                    [[ -f "${root}/${f}.${t}"  ]] && { file="${root}/${f}.${t}";  break 2; }
                fi

            done

        done

    fi

    [[ -f "${file}" ]] || { err "Missing ${type} file"; return 1; }
    out "${file}"

}
varfile () {

    envfile "${1:-}" "${2:-}" variable

}
secfile () {

    envfile "${1:-}" "${2:-}" secret

}

envkey () {

    local file="${1:-}"

    [[ -f "${file}" ]] || file="$(secfile "$@" 2>/dev/null || true)"
    [[ -f "${file}" ]] || file="$(varfile "$@" 2>/dev/null || true)"
    [[ -f "${file}" ]] || file="$(envfile "$@" 2>/dev/null || true)"
    [[ -f "${file}" ]] || { err "Missing secret|variable|env file"; return 1; }

    encodefile "${file}"

}
sshkey () {

    local file="${1:-}"

    [[ -f "${file}" ]] || file="${HOME}/.ssh/id_ed25519"
    [[ -f "${file}" ]] || file="${HOME}/.ssh/id_ecdsa"
    [[ -f "${file}" ]] || file="${HOME}/.ssh/id_rsa"
    [[ -f "${file}" ]] || { err "Missing ssh file"; return 1; }

    encodefile "${file}"

}
pemkey () {

    local name="${1:-aws}" file=""

    file="$(find "${HOME}/.ssh" -maxdepth 1 -type f -name "${name}*.pem" | sort | head -n 1)"
    [[ -n "${file}" && -f "${file}" ]] || { err "Missing pem key: ${name}*.pem"; return 1; }

    encodefile "${file}"

}
