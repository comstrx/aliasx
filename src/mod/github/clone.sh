
clone-list () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return

    gh api "repos/${name}/traffic/clones" "$@" 2>/dev/null \
        || { err "Failed to list clones. Requires repository access."; return; }

}
clones () {

    clone-list "$@" --jq '.count'

}
clone () {

    need gh || return

    local name="${1:-}" dir="${2:-}"

    shift >/dev/null 2>&1 || true

    [[ "${dir}" == --* ]] && dir=""
    [[ -n "${dir}" ]] && { shift >/dev/null 2>&1 || true; }

    name="$(repo "${name}")" || return

    if [[ -n "${dir}" ]]; then

        gh repo clone "${name}" "${dir}" "$@" \
            || { err "Failed to clone repository: ${name}"; return; }

        succ "Cloned: ${name} -> ${dir}"
        return

    fi

    gh repo clone "${name}" "$@" \
        || { err "Failed to clone repository: ${name}"; return; }

    succ "Cloned: ${name}"

}
pull () {

    need git || return

    local branch="${1:-}" pull_out="" name=""

    [[ "${branch}" == --* ]] && branch=""
    [[ -n "${branch}" ]] && { shift >/dev/null 2>&1 || true; }

    if ! isrepo; then

        name="${branch:-"$(basename -- "$(pwd -P)")"}"

        clone "${name}" . "$@" || { err "Not a git repository"; return; }
        return

    fi

    [[ -n "${branch}" ]] || branch="$(git branch --show-current 2>/dev/null)"
    [[ -n "${branch}" ]] || branch="$(default-branch 2>/dev/null)"
    [[ -n "${branch}" ]] || branch="main"

    if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then

        pull_out="$(git pull "$@" 2>&1)" \
            || { printf '%s\n' "${pull_out}" >&2; err "Failed to pull"; return; }

    else

        pull_out="$(git pull origin "${branch}" "$@" 2>&1)" \
            || { printf '%s\n' "${pull_out}" >&2; err "Failed to pull"; return; }

    fi

    if [[ "${pull_out,,}" == *already\ up\ to\ date* || "${pull_out,,}" == *up-to-date* ]]; then
        succ "Up to date"
    else
        succ "Pulled"
    fi

}
