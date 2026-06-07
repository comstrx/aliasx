
tag-list () {

    need git || return

    git tag --sort=-v:refname "$@"

}
tags () {

    need git || return

    git tag --list "$@" | awk 'END { print NR + 0 }'

}

tag-exists () {

    need git || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(tag "${name}")" || return

    git rev-parse -q --verify "refs/tags/${name}" "$@" >/dev/null 2>&1

}
find-tag () {

    need git || return

    local query="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${query}" ]] || { err "Missing tag query"; return; }
    git tag --list "*${query}*" "$@"

}

tag-released () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(tag "${name}")" || return

    gh release view "${name}" "$@" >/dev/null 2>&1

}
tag-release () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(tag "${name}")" || return

    gh release view "${name}" --json url -q '.url' "$@" 2>/dev/null \
        || { err "Release not found: ${name}"; return; }

}

new-tag () {

    need git || return

    local name="${1:-}" force="${2:-0}"
    shift >/dev/null 2>&1 || true

    [[ $# -gt 0 ]] && { shift >/dev/null 2>&1 || true; }

    name="$(tag "${name}")" || return

    if tag-exists "${name}"; then

        bool "${force}" force f || return 0
        git tag -d "${name}" >/dev/null 2>&1 || true

        git push origin --delete "${name}" "$@" >/dev/null 2>&1 \
            || { err "Failed to delete remote tag: ${name}"; return; }

    fi

    git tag "${name}" >/dev/null 2>&1 \
        || { err "Failed to create tag: ${name}"; return; }

    git push origin "${name}" "$@" >/dev/null 2>&1 \
        || { err "Failed to push tag: ${name}"; return; }

    succ "Tag ready -> ${name}"

}
del-tag () {

    need git || return
    need gh  || return

    local name="${1:-}" force="${2:-0}"
    shift >/dev/null 2>&1 || true

    [[ $# -gt 0 ]] && { shift >/dev/null 2>&1 || true; }
    name="$(tag "${name}")" || return

    if tag-released "${name}"; then
        bool "${force}" force f || { err "Tag has release: ${name}"; return; }
    fi

    git tag -d "${name}" >/dev/null 2>&1 || true

    git push origin --delete "${name}" "$@" >/dev/null 2>&1 \
        || { err "Failed to delete remote tag: ${name}"; return; }

    succ "Tag deleted -> ${name}"

}
