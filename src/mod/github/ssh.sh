
ssh-id () {

    need gh || return

    local key="${1:-}" id=""
    shift >/dev/null 2>&1 || true

    [[ -n "${key}" ]] || { err "Missing SSH key id/title"; return; }

    id="$(
        gh api user/keys --paginate \
            --jq ".[] | select((.id|tostring)==\"${key}\" or .title==\"${key}\") | .id" \
            "$@" 2>/dev/null | head -n 1
    )"

    [[ -n "${id}" ]] || { err "SSH key not found: ${key}"; return; }

    out "${id}"

}

ssh-exists () {

    need gh || return

    local key="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${key}" ]] || { err "Missing SSH key id/title"; return; }
    ssh-id "${key}" "$@" >/dev/null 2>&1

}
find-ssh () {

    need gh || return

    local key="${1:-}" id=""
    shift >/dev/null 2>&1 || true

    [[ -n "${key}" ]] || { err "Missing SSH key id/title"; return; }

    id="$(ssh-id "${key}" "$@")" || return

    gh api user/keys --paginate --jq ".[] | select((.id|tostring)==\"${id}\")" "$@" 2>/dev/null \
        || { err "SSH key not found: ${key}"; return; }

}

add-ssh () {

    need ssh-keygen || return
    need ssh-add    || return
    need gh         || return

    local name="${1:-id_ed25519}" email="${2:-}" force="${3:-0}" title="" key="" pub=""

    if bool "${name}" force f; then force=1; name=""
    elif bool "${email}" force f; then force=1; email=""
    elif bool "${force}" force f; then force=1
    else force=0
    fi

    name="${name:-id_ed25519}"
    key="${HOME}/.ssh/${name}"
    pub="${key}.pub"
    title="$(hostname)-${name}"

    mkdir -p -- "${HOME}/.ssh" || { err "Failed to create ~/.ssh"; return; }
    chmod 700 -- "${HOME}/.ssh" >/dev/null 2>&1 || true

    [[ -n "${email}" ]] || email="$(gh api user -q .email 2>/dev/null || true)"
    [[ -n "${email}" ]] || email="${USER}@$(hostname)"

    if [[ -f "${key}" || -f "${key}.pub" ]]; then

        (( force )) || { err "SSH key already exists: ${key}. Use force/-f to reset it."; return; }
        rm -f -- "${key}" "${pub}" >/dev/null 2>&1 || true

    fi

    ssh-keygen -t ed25519 -C "${email}" -f "${key}" -N "" >/dev/null 2>&1 \
        || { err "Failed to generate SSH key: ${key}"; return; }

    chmod 600 -- "${key}" >/dev/null 2>&1 || true
    chmod 644 -- "${pub}" >/dev/null 2>&1 || true

    [[ -n "${SSH_AUTH_SOCK:-}" ]] || { eval "$(ssh-agent -s)" >/dev/null 2>&1 || true; }

    ssh-add "${key}" >/dev/null 2>&1 || true
    gh ssh-key add "${pub}" --title "${title}" >/dev/null 2>&1 || { err "Failed to add SSH key to GitHub"; return; }

    succ "SSH key added -> ${title}"

}
del-ssh () {

    need gh || return

    local key="${1:-}" id=""
    shift >/dev/null 2>&1 || true

    [[ -n "${key}" ]] || { err "Missing SSH key id/title"; return; }

    id="$(ssh-id "${key}" "$@")" || return

    gh ssh-key delete "${id}" --yes "$@" >/dev/null 2>&1 \
        || { err "Failed to delete SSH key: ${key}"; return; }

    succ "SSH key deleted -> ${key}"

}

ssh-list () {

    need gh || return
    gh api user/keys --paginate "$@"

}
