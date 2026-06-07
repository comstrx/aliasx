
branch-list () {

    need git || return
    git branch --no-color --all "$@"

}
branches () {

    need git || return
    isrepo   || { err "Not a git repository"; return; }

    git fetch --prune origin >/dev/null 2>&1 || true
    git branch -r | grep -v 'origin/HEAD' | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' '

}

branch-exists () {

    need git || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${name}" ]] || { err "Missing branch name"; return; }

    git rev-parse --verify "refs/heads/${name}" "$@" >/dev/null 2>&1 \
        || git ls-remote --exit-code --heads origin "${name}" "$@" >/dev/null 2>&1

}
find-branch () {

    need git || return

    local query="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${query}" ]] || { err "Missing branch query"; return; }

    git branch --no-color --all --list "*${query}*" "$@"

}

new-branch () {

    need git || return

    local name="${1:-}" base="${2:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${name}" ]] || { err "Missing branch name"; return; }

    if [[ "${base}" == --* ]]; then base=""
    else shift >/dev/null 2>&1 || true
    fi

    if git rev-parse --verify "refs/heads/${name}" >/dev/null 2>&1; then

        git switch "${name}" "$@" >/dev/null 2>&1 \
            || { err "Failed to switch branch: ${name}"; return; }

    elif git ls-remote --exit-code --heads origin "${name}" >/dev/null 2>&1; then

        git switch -c "${name}" --track "origin/${name}" "$@" >/dev/null 2>&1 \
            || { err "Failed to track branch: ${name}"; return; }

    elif [[ -n "${base}" ]]; then

        git switch -c "${name}" "${base}" "$@" >/dev/null 2>&1 \
            || { err "Failed to create branch: ${name}"; return; }

    else

        git switch -c "${name}" "$@" >/dev/null 2>&1 \
            || { err "Failed to create branch: ${name}"; return; }

    fi

    succ "Branch ready -> ${name}"

}
del-branch () {

    need git || return

    local name="${1:-}" force="${2:-0}" current="" local_ok=0 remote_ok=0

    shift >/dev/null 2>&1 || true
    [[ $# -gt 0 ]] && { shift >/dev/null 2>&1 || true; }
    [[ -n "${name}" ]] || { err "Missing branch name"; return; }

    current="$(current-branch 2>/dev/null || true)"

    [[ "${name}" != "${current}" ]] || { err "Cannot delete current branch: ${name}"; return; }

    if bool "${force}" force f; then git branch -D "${name}" >/dev/null 2>&1 && local_ok=1
    else git branch -d "${name}" >/dev/null 2>&1 && local_ok=1
    fi

    git push origin --delete "${name}" "$@" >/dev/null 2>&1 && remote_ok=1

    (( local_ok || remote_ok )) || { err "Branch not found: ${name}"; return; }

    succ "Branch deleted -> ${name}"

}

current-branch () {

    need git || return
    git branch --show-current "$@" 2>/dev/null || { err "Failed to detect current branch"; return; }

}
default-branch () {

    need gh || return

    local name=""
    name="$(repo)" || return

    gh repo view "${name}" --json defaultBranchRef -q '.defaultBranchRef.name' "$@" 2>/dev/null \
        || { err "Failed to detect default branch: ${name}"; return; }

}
sync-branch () {

    need git || return

    local branch="" main=""

    isrepo || { err "Not a git repository"; return; }

    git diff --quiet || { err "Working tree has unstaged changes"; return; }
    git diff --cached --quiet || { err "Working tree has staged changes"; return; }

    branch="$(current-branch)" || return
    main="$(default-branch 2>/dev/null)"

    [[ -n "${branch}" ]] || { err "Detached HEAD"; return; }
    [[ -n "${main}" ]] || main="main"

    git fetch --prune origin || { err "Failed to fetch origin"; return; }

    if [[ "${branch}" == "${main}" ]]; then

        git pull --ff-only origin "${main}" \
            || { err "Failed to sync ${main}"; return; }

    else

        if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then

            git merge --ff-only "@{u}" >/dev/null 2>&1 \
                || { err "Branch diverged from remote: ${branch}"; return; }

        fi

        git rebase "origin/${main}" \
            || { err "Failed to rebase ${branch} on ${main}"; return; }

    fi

    succ "Branch synced -> ${branch}"

}

set-branch () {

    need git || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${name}" ]] || { err "Missing branch name"; return; }

    git switch "${name}" "$@" >/dev/null 2>&1 && { succ "Switched -> ${name}"; return; }

    git switch -c "${name}" --track "origin/${name}" "$@" >/dev/null 2>&1 \
        || { err "Failed to switch branch: ${name}"; return; }

    succ "Switched -> ${name}"

}
set-default-branch () {

    need gh || return

    local name="${1:-}" repo_name=""
    shift >/dev/null 2>&1 || true

    [[ -n "${name}" ]] || { err "Missing branch name"; return; }
    repo_name="$(repo)" || return

    gh api --method PATCH "repos/${repo_name}" -f "default_branch=${name}" "$@" >/dev/null 2>&1 \
        || { err "Failed to set default branch: ${name}"; return; }

    succ "Default branch set -> ${name}"

}
