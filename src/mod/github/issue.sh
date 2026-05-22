
issue-list () {

    need gh || return

    local name="${1:-}" state="${2:-open}"

    if [[ -n "${name}" && "${name}" != --* && "${name}" != [0-9]* ]]; then

        shift >/dev/null 2>&1 || true
        [[ "${state}" == --* ]] && state="open" || shift >/dev/null 2>&1 || true

        name="$(repo "${name}")" || return
        gh issue list --repo "${name}" --state "${state}" "$@"

        return

    fi

    gh issue list "$@"

}
issues () {

    need gh || return

    local name="${1:-}" state="${2:-open}"

    if [[ -n "${name}" && "${name}" != --* && "${name}" != [0-9]* ]]; then

        shift >/dev/null 2>&1 || true
        [[ "${state}" == --* ]] && state="open" || shift >/dev/null 2>&1 || true

        name="$(repo "${name}")" || return
        gh issue list --repo "${name}" --state "${state}" --json number -q 'length' "$@"

        return

    fi

    gh issue list --json number -q 'length' "$@"

}

issue-open () {

    need gh || return

    local id="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${id}" ]] || { err "Missing issue number or url"; return; }

    gh issue view "${id}" --web "$@" \
        || { err "Failed to open issue: ${id}"; return; }

}
issue-view () {

    need gh || return

    local id="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${id}" ]] || { err "Missing issue number or url"; return; }

    gh issue view "${id}" "$@" \
        || { err "Failed to view issue: ${id}"; return; }

}
issue-new () {

    need gh || return

    gh issue create "$@" \
        || { err "Failed to create issue"; return; }

}
issue-close () {

    need gh || return

    local id="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${id}" ]] || { err "Missing issue number or url"; return; }

    gh issue close "${id}" "$@" \
        || { err "Failed to close issue: ${id}"; return; }

    succ "Issue closed: ${id}"

}
issue-reopen () {

    need gh || return

    local id="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${id}" ]] || { err "Missing issue number or url"; return; }

    gh issue reopen "${id}" "$@" \
        || { err "Failed to reopen issue: ${id}"; return; }

    succ "Issue reopened: ${id}"

}
issue-comment () {

    need gh || return

    local id="${1:-}" body="${2:-}"
    shift 2 >/dev/null 2>&1 || true

    [[ -n "${id}"   ]] || { err "Missing issue number or url"; return; }
    [[ -n "${body}" ]] || { err "Missing issue comment"; return; }

    gh issue comment "${id}" --body "${body}" "$@" \
        || { err "Failed to comment on issue: ${id}"; return; }

    succ "Issue commented: ${id}"

}
