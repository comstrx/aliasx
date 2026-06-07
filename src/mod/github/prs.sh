
pr-list () {

    need gh || return

    local name="${1:-}" state="${2:-open}"

    if [[ -n "${name}" && "${name}" != --* && "${name}" != [0-9]* ]]; then

        shift >/dev/null 2>&1 || true

        if [[ "${state}" == --* ]]; then state="open"
        else shift >/dev/null 2>&1 || true
        fi

        name="$(repo "${name}")" || return
        gh pr list --repo "${name}" --state "${state}" "$@"

        return

    fi

    gh pr list "$@"

}
prs () {

    need gh || return

    local name="${1:-}" state="${2:-open}"

    if [[ -n "${name}" && "${name}" != --* && "${name}" != [0-9]* ]]; then

        shift >/dev/null 2>&1 || true

        if [[ "${state}" == --* ]]; then state="open"
        else shift >/dev/null 2>&1 || true
        fi

        name="$(repo "${name}")" || return
        gh pr list --repo "${name}" --state "${state}" --json number -q 'length' "$@"

        return

    fi

    gh pr list --json number -q 'length' "$@"

}
pr-open () {

    need gh || return

    local id="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${id}" ]] || { err "Missing PR number/url/branch"; return; }

    gh pr view "${id}" --web "$@" || { err "Failed to open PR: ${id}"; return; }

}
pr-view () {

    need gh || return

    local id="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${id}" ]] || { err "Missing PR number/url/branch"; return; }

    gh pr view "${id}" "$@" || { err "Failed to view PR: ${id}"; return; }

}
pr-new () {

    need gh || return

    gh pr create "$@" || { err "Failed to create PR"; return; }

}

pr-checks () {

    need gh || return

    gh pr checks "$@"

}
pr-ready () {

    need gh || return

    local id="${1:-}"
    shift >/dev/null 2>&1 || true

    if [[ -n "${id}" && "${id}" != --* ]]; then
        gh pr ready "${id}" "$@" || { err "Failed to mark PR ready: ${id}"; return; }
    else
        gh pr ready "$@" || { err "Failed to mark PR ready"; return; }
    fi

    succ "PR ready"

}
pr-merge () {

    need gh || return

    local id="${1:-}"
    shift >/dev/null 2>&1 || true

    if [[ -n "${id}" && "${id}" != --* ]]; then
        gh pr merge "${id}" "$@" || { err "Failed to merge PR: ${id}"; return; }
    else
        gh pr merge "$@" || { err "Failed to merge PR"; return; }
    fi

    succ "PR merged"

}
pr-close () {

    need gh || return

    local id="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${id}" ]] || { err "Missing PR number/url/branch"; return; }

    gh pr close "${id}" "$@" || { err "Failed to close PR: ${id}"; return; }

    succ "PR closed: ${id}"

}

pr-reopen () {

    need gh || return

    local id="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${id}" ]] || { err "Missing PR number/url/branch"; return; }

    gh pr reopen "${id}" "$@" || { err "Failed to reopen PR: ${id}"; return; }

    succ "PR reopened: ${id}"

}
pr-diff () {

    need gh || return

    local id="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${id}" ]] || { err "Missing PR number/url/branch"; return; }
    gh pr diff "${id}" "$@" || { err "Failed to diff PR: ${id}"; return; }

}
pr-checkout () {

    need gh || return

    local id="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${id}" ]] || { err "Missing PR number/url/branch"; return; }

    gh pr checkout "${id}" "$@" || { err "Failed to checkout PR: ${id}"; return; }

    succ "PR checked out: ${id}"

}
