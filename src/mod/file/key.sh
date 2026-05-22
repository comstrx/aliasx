
envkey () {

    local mode="${1:-production}" file="${2:-}"

    [[ -z "${file}" && -f "${mode}" ]] && { file="${mode}"; mode=""; }
    [[ -f "${file}" ]] || file="$(envfile "${mode}" "${file}" 2>/dev/null || true)"
    [[ -f "${file}" ]] || file="$(varfile "${mode}" "${file}" 2>/dev/null || true)"
    [[ -f "${file}" ]] || file="$(secfile "${mode}" "${file}" 2>/dev/null || true)"
    [[ -f "${file}" ]] || { err "Missing secret|variable|env file"; return 1; }

    encodefile "${file}"

}
sshkey () {

    local file="${1:-}"

    [[ -f "${file}" ]] || file="${HOME}/.ssh/id_ed25519"
    [[ -f "${file}" ]] || file="${HOME}/.ssh/id_ecdsa"
    [[ -f "${file}" ]] || file="${HOME}/.ssh/id_rsa"
    [[ -f "${file}" ]] || file="${HOME}/.ssh/id_${file}"
    [[ -f "${file}" ]] || file="${HOME}/.ssh/${file}"
    [[ -f "${file}" ]] || file="${HOME}/${file}"
    [[ -f "${file}" ]] || { err "Missing ssh file"; return 1; }

    encodefile "${file}"

}
pemkey () {

    local name="${1:-aws}" file=""

    file="$(find "${HOME}/.ssh" -maxdepth 1 -type f -name "${name}*.pem" | sort | head -n 1)"
    [[ -n "${file}" && -f "${file}" ]] || { err "Missing pem key: ${name}*.pem"; return 1; }

    encodefile "${file}"

}
