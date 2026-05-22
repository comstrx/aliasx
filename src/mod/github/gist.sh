
gist-list () {

    need gh || return

    gh gist list "$@"

}
gists () {

    need gh || return

    local limit="100"

    if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
        limit="${1}"
        shift
    fi

    gh gist list --limit "${limit}" "$@" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' '

}

gist-new () {

    need gh || return

    [[ $# -gt 0 ]] || { err "Missing gist file or content"; return; }

    gh gist create "$@" \
        || { err "Failed to create gist"; return; }

}
gist-open () {

    need gh || return

    local id="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${id}" ]] || { err "Missing gist id"; return; }

    gh gist view "${id}" --web "$@" \
        || { err "Failed to open gist: ${id}"; return; }

}
gist-view () {

    need gh || return

    local id="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${id}" ]] || { err "Missing gist id"; return; }

    gh gist view "${id}" "$@" \
        || { err "Failed to view gist: ${id}"; return; }

}
gist-delete () {

    need gh || return

    local id="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${id}" ]] || { err "Missing gist id"; return; }

    gh gist delete "${id}" "$@" \
        || { err "Failed to delete gist: ${id}"; return; }

    succ "Gist deleted: ${id}"

}
