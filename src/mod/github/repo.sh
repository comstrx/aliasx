
repo-exists () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return
    gh repo view "${name}" "$@" >/dev/null 2>&1

}
find-repo () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return

    gh repo view "${name}" "$@" >/dev/null 2>&1 \
        && { succ "Repository: ${name}"; return; }

    err "Repository not found: ${name}"

}

new-repo () {

    need gh || return

    local name="${1:-}" visibility="${2:-}"
    shift >/dev/null 2>&1 || true

    case "${visibility}" in
        pub*|--pub*) visibility="--public"; shift >/dev/null 2>&1 || true;;
        pri*|--pri*) visibility="--private"; shift >/dev/null 2>&1 || true;;
        *)           visibility="--private" ;;
    esac

    name="$(name "${name}")" || return
    name="$(repo "${name}")" || return

    repo-exists "${name}" && { warn "Repository already exists: ${name}"; return; }

    gh repo create "${name}" "${visibility}" "$@" >/dev/null 2>&1 \
        || { err "Failed to create repository: ${name}"; return; }

    succ "Repository created: ${name}"

}
del-repo () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return

    gh repo delete "${name}" --yes "$@" >/dev/null 2>&1 \
        || { err "Failed to delete repository: ${name}"; return; }

    succ "Repository deleted: ${name}"

}

archive-repo () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return

    gh repo archive "${name}" --yes "$@" >/dev/null 2>&1 \
        || { err "Failed to archive repository: ${name}"; return; }

    succ "Repository archived: ${name}"

}
unarchive-repo () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return

    gh repo unarchive "${name}" --yes "$@" >/dev/null 2>&1 \
        || { err "Failed to unarchive repository: ${name}"; return; }

    succ "Repository unarchived: ${name}"

}
rename-repo () {

    need gh || return

    local old="${1:-}" new="${2:-}"
    shift 2 >/dev/null 2>&1 || true

    old="$(repo "${old}")" || return

    [[ -n "${new}" ]] || new="$(basename -- "$(rroot 2>/dev/null)")" || return
    [[ "${old##*/}" != "${new}" ]] || { err "New name and old name are the same"; return; }

    gh repo rename "${new}" --repo "${old}" --yes "$@" >/dev/null 2>&1 \
        || { err "Failed to rename repository: ${old} -> ${new}"; return; }

    succ "Repository renamed -> ${old%/*}/${new}"

}

repo-list () {

    need gh || return

    gh repo list --limit 100 "$@"

}
