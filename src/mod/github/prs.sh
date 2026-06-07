
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

    gh pr view "$@" --web || { err "Failed to open PR"; return; }

}
pr-view () {

    need gh || return

    gh pr view "$@" || { err "Failed to view PR"; return; }

}
pr-diff () {

    need gh || return

    gh pr diff "$@" || { err "Failed to diff PR"; return; }

}
pr-checkout () {

    need gh || return

    gh pr checkout "$@" || { err "Failed to checkout PR"; return; }

}

pr-checks () {

    need gh || return

    gh pr checks "$@" || { err "Failed to check PR"; return; }

}
pr-ready () {

    need gh || return

    gh pr ready "$@" || { err "Failed to mark PR ready"; return; }

}
pr-merge () {

    need gh || return

    gh pr merge --squash "$@" || { err "Failed to merge PR"; return; }

}

pr-new () {

    need gh || return

    gh pr create "$@" || { err "Failed to create PR"; return; }

}
pr-close () {

    need gh || return

    gh pr close "$@" || { err "Failed to close PR"; return; }

}
pr-reopen () {

    need gh || return

    gh pr reopen "$@" || { err "Failed to reopen PR"; return; }

}
