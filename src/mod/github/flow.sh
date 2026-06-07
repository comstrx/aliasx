
flow-list () {

    need gh || return

    gh workflow list "$@"

}
flows () {

    need gh || return

    gh workflow list --json id -q 'length' "$@"

}
flow-view () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${name}" ]] || { err "Missing workflow name/id"; return; }

    gh workflow view "${name}" "$@" \
        || { err "Failed to view workflow: ${name}"; return; }

}
flow-run () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${name}" ]] || { err "Missing workflow name/id"; return; }

    gh workflow run "${name}" "$@" \
        || { err "Failed to run workflow: ${name}"; return; }

    succ "Workflow triggered: ${name}"

}
flow-enable () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${name}" ]] || { err "Missing workflow name/id"; return; }

    gh workflow enable "${name}" "$@" \
        || { err "Failed to enable workflow: ${name}"; return; }

    succ "Workflow enabled: ${name}"

}
flow-disable () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${name}" ]] || { err "Missing workflow name/id"; return; }

    gh workflow disable "${name}" "$@" \
        || { err "Failed to disable workflow: ${name}"; return; }

    succ "Workflow disabled: ${name}"

}

run-list () {

    need gh || return

    gh run list "$@"

}
runs () {

    need gh || return

    local limit="100"

    if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
        limit="${1}"
        shift
    fi

    gh run list --limit "${limit}" --json databaseId -q 'length' "$@"

}
run-view () {

    need gh || return

    local id="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${id}" ]] || { err "Missing run id"; return; }

    gh run view "${id}" "$@" \
        || { err "Failed to view run: ${id}"; return; }

}
run-open () {

    need gh || return

    local id="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${id}" ]] || { err "Missing run id"; return; }

    gh run view "${id}" --web "$@" \
        || { err "Failed to open run: ${id}"; return; }

}
run-watch () {

    need gh || return

    local id="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${id}" ]] || { err "Missing run id"; return; }

    gh run watch "${id}" "$@" \
        || { err "Failed to watch run: ${id}"; return; }

}
run-rerun () {

    need gh || return

    local id="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${id}" ]] || { err "Missing run id"; return; }

    gh run rerun "${id}" "$@" \
        || { err "Failed to rerun: ${id}"; return; }

    succ "Run rerun: ${id}"

}
run-cancel () {

    need gh || return

    local id="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${id}" ]] || { err "Missing run id"; return; }

    gh run cancel "${id}" "$@" \
        || { err "Failed to cancel run: ${id}"; return; }

    succ "Run cancelled: ${id}"

}
