
set-var () {

    need gh || return

    local name="${1:-}" value="${2:-}" encode="${3:-}" type="${4:-}"

    shift 2 >/dev/null 2>&1 || true

    case "${type,,}" in
        sec*) type="secret"; shift >/dev/null 2>&1 || true ;;
        var*) type="variable"; shift >/dev/null 2>&1 || true ;;
        *)    type="variable" ;;
    esac

    [[ -n "${name}"  ]] || { err "Missing ${type} key"; return; }
    [[ -n "${value}" ]] || { err "Missing ${type} value"; return; }

    case "${encode,,}" in
        --encode|--base64|--b64) encode=1; shift >/dev/null 2>&1 || true ;;
        --no-encode) encode=0; shift >/dev/null 2>&1 || true ;;
        *) encode=0 ;;
    esac

    if (( encode )); then
        value="$(printf '%s' "${value}" | base64 | tr -d '\n')" || { err "Failed to encode value"; return; }
    fi

    printf '%s' "${value}" | gh "${type}" set "${name}" "$@" >/dev/null 2>&1 \
        || { err "Failed to add ${type}: ${name}"; return; }

    succ "${type^} added: ${name}"

}
get-var () {

    need gh || return

    local name="${1:-}" decode="${2:-}" type="${3:-}" value=""

    shift >/dev/null 2>&1 || true

    case "${type,,}" in
        sec*) type="secret"; shift >/dev/null 2>&1 || true ;;
        var*) type="variable"; shift >/dev/null 2>&1 || true ;;
        *)    type="variable" ;;
    esac

    [[ -n "${name}" ]] || { err "Missing ${type} key"; return; }

    case "${decode,,}" in
        --decode|--base64|--b64) decode=1; shift >/dev/null 2>&1 || true ;;
        --no-decode) decode=0; shift >/dev/null 2>&1 || true ;;
        *) decode=0 ;;
    esac

    if [[ "${type}" == "secret" ]]; then

        gh secret list "$@" 2>/dev/null | awk '{print $1}' | grep -Fxq -- "${name}" \
            || { err "Secret not found: ${name}"; return; }

        out "****"
        return

    fi

    value="$(gh variable get "${name}" --json value -q '.value' "$@" 2>/dev/null)" \
        || { err "Variable not found: ${name}"; return; }

    if (( decode )); then printf '%s' "${value}" | base64 -d; printf '\n'
    else out "${value}"
    fi

}
del-var () {

    need gh || return

    local name="${1:-}" type="${2:-}"

    shift >/dev/null 2>&1 || true

    case "${type,,}" in
        sec*) type="secret"; shift >/dev/null 2>&1 || true ;;
        var*) type="variable"; shift >/dev/null 2>&1 || true ;;
        *)    type="variable" ;;
    esac

    [[ -n "${name}" ]] || { err "Missing ${type} key"; return; }

    gh "${type}" delete "${name}" "$@" >/dev/null 2>&1 \
        || { err "Failed to delete ${type}: ${name}"; return; }

    succ "${type^} deleted: ${name}"

}
push-vars () {

    need gh || return

    local file="${1:-}" type="${2:-}"

    case "${type,,}" in
        sec*) type="secret"; shift >/dev/null 2>&1 || true ;;
        var*) type="variable"; shift >/dev/null 2>&1 || true ;;
        *)    type="variable" ;;
    esac

    if [[ "${file}" == --* ]]; then file=""
    else shift >/dev/null 2>&1 || true
    fi

    if [[ ! -f "${file}" ]]; then

        if [[ "${type}" == "secret" ]]; then file="$(secfile "${file}" 2>/dev/null || true)"
        else file="$(varfile "${file}" 2>/dev/null || true)"
        fi

        [[ -f "${file}" ]] || { err "Missing ${type}s file"; return; }

    fi

    gh "${type}" set -f "${file}" "$@" >/dev/null 2>&1 \
        || { err "Failed to set ${type}s: ${file}"; return; }

    succ "${type^}s pushed from: ${file}"

}
del-vars () {

    need gh || return

    local type="${1:-}" name=""

    local -a keys=()

    case "${type,,}" in
        sec*) type="secret"; shift >/dev/null 2>&1 || true ;;
        var*) type="variable"; shift >/dev/null 2>&1 || true ;;
        *)    type="variable" ;;
    esac

    mapfile -t keys < <(gh "${type}" list "$@" --json name -q '.[].name' 2>/dev/null)

    [[ "${#keys[@]}" -gt 0 ]] || { warn "No ${type}s found"; return; }

    for name in "${keys[@]}"; do

        [[ -n "${name}" ]] || continue

        gh "${type}" delete "${name}" "$@" >/dev/null 2>&1 \
            || { err "Failed to delete ${type}: ${name}"; return; }

    done

    succ "${type^}s deleted"

}
sync-vars () {

    need gh || return

    local file="${1:-}" type="${2:-}"

    case "${type,,}" in
        sec*) type="secret"; shift >/dev/null 2>&1 || true ;;
        var*) type="variable"; shift >/dev/null 2>&1 || true ;;
        *)    type="variable" ;;
    esac

    if [[ "${file}" == --* ]]; then file=""
    else shift >/dev/null 2>&1 || true
    fi

    if [[ ! -f "${file}" ]]; then

        if [[ "${type}" == "secret" ]]; then file="$(secfile "${file}" 2>/dev/null || true)"
        else file="$(varfile "${file}" 2>/dev/null || true)"
        fi

        [[ -f "${file}" ]] || { err "Missing ${type}s file"; return; }

    fi

    (
        local remote="" tmp_local="" tmp_remote="" tmp_delete=""

        tmp_local="$(mktemp)"  || { err "Failed to create temp file"; return; }
        tmp_remote="$(mktemp)" || { err "Failed to create temp file"; return; }
        tmp_delete="$(mktemp)" || { err "Failed to create temp file"; return; }

        trap 'rm -f "${tmp_local}" "${tmp_remote}" "${tmp_delete}"' EXIT

        awk -F= '
            { sub(/\r$/, ""); sub(/^[[:space:]]*export[[:space:]]+/, "") }
            /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
            /^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=/
            { key=$1; gsub(/^[[:space:]]+|[[:space:]]+$/, "", key); print key }
        ' "${file}" | sort -u > "${tmp_local}" || { err "Failed to parse local ${type}s file: ${file}"; return; }

        gh "${type}" set -f "${file}" "$@" >/dev/null 2>&1 \
            || { err "Failed to set ${type}s: ${file}"; return; }

        gh "${type}" list "$@" --json name -q '.[].name' 2>/dev/null | sort -u > "${tmp_remote}" \
            || { err "Failed to list ${type}s"; return; }

        comm -23 "${tmp_remote}" "${tmp_local}" > "${tmp_delete}" \
            || { err "Failed to compare ${type}s"; return; }

        while IFS= read -r remote; do

            [[ -n "${remote}" ]] || continue

            gh "${type}" delete "${remote}" "$@" >/dev/null 2>&1 \
                || { err "Failed to delete ${type}: ${remote}"; return; }

        done < "${tmp_delete}"

    ) || return

    succ "${type^}s synced from: ${file}"

}
var-list () {

    need gh || return

    local type="${1:-}"

    case "${type,,}" in
        sec*) type="secret"; shift >/dev/null 2>&1 || true ;;
        var*) type="variable"; shift >/dev/null 2>&1 || true ;;
        *)    type="variable" ;;
    esac

    gh "${type}" list "$@"

}

set-secret () {

    local name="${1:-}" value="${2:-}" encode="${3:-}"
    shift 2 >/dev/null 2>&1 || true

    case "${encode,,}" in
        --encode|--base64|--b64) shift >/dev/null 2>&1 || true ;;
        *) encode="--no-encode" ;;
    esac

    set-var "${name}" "${value}" "${encode}" secret "$@"

}
get-secret () {

    local name="${1:-}" decode="${2:-}"
    shift >/dev/null 2>&1 || true

    case "${decode,,}" in
        --decode|--base64|--b64) shift >/dev/null 2>&1 || true ;;
        *) decode="--no-decode" ;;
    esac

    get-var "${name}" "${decode}" secret "$@"

}
del-secret () {

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    del-var "${name}" secret "$@"

}
push-secrets () {

    local file="${1:-}"
    shift >/dev/null 2>&1 || true

    push-vars "${file}" secret "$@"

}
del-secrets () {

    del-vars secret "$@"

}
sync-secrets () {

    local file="${1:-}"
    shift >/dev/null 2>&1 || true

    sync-vars "${file}" secret "$@"

}
secret-list () {

    var-list secret "$@"

}
