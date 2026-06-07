
fork-list () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return
    gh api "repos/${name}/forks" --paginate "$@"

}
forks () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return
    gh repo view "${name}" --json forkCount -q '.forkCount' "$@"

}
fork () {

    need gh || return

    local name="${1:-}" login="" fork="" parent=""
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return
    login="$(owner)" || return

    fork="${login}/${name##*/}"

    if [[ "${fork}" == "${name}" ]]; then

        succ "Repository already belongs to you: ${name}"
        return

    fi
    if parent="$(gh repo view "${fork}" --json parent -q '.parent.nameWithOwner // ""' 2>/dev/null)"; then

        [[ "${parent}" == "${name}" ]] || { err "Repository exists but is not a fork of ${name}: ${fork}"; return; }

        gh repo sync "${fork}" "$@" >/dev/null 2>&1 \
            || { err "Failed to sync fork: ${fork}"; return; }

        succ "Fork synced: ${fork}"
        return

    fi

    gh repo fork "${name}" --clone=false "$@" >/dev/null 2>&1 \
        || { err "Failed to fork repository: ${name}"; return; }

    succ "Repository forked: ${fork}"

}
