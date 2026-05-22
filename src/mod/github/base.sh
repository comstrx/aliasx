
isrepo () {

    need git || return

    git rev-parse --is-inside-work-tree >/dev/null 2>&1

}
repo () {

    need gh || return

    local name="${1:-}" login=""

    if [[ -z "${name}" ]]; then

        gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null \
            || { err "Not a git repository"; return; }

        return 0

    fi

    [[ "${name}" == */* ]] && { out "${name}"; return; }

    login="$(gh api user -q .login 2>/dev/null)" || { err "Failed to detect Github user"; return; }

    [[ -n "${login}" ]] || { err "Failed to detect Github user"; return; }

    out "${login}/${name}"

}
rroot () {

    local dir=""

    dir="$(git rev-parse --show-toplevel 2>/dev/null)" && { out "${dir}"; return; }
    out "$(pwd -P)"

}
cdrepo () {

    cd "$(rroot)" || { err "cannot cd repo root"; return; }

}

branch () {

    need git || return

    git branch --show-current 2>/dev/null \
        || { err "Failed to detect current branch"; return; }

}
tag () {

    local tag="${1:-${TAG:-${VERSION:-${APP_TAG:-}}}}"

    tag="${tag#v}"
    [[ -n "${tag}" ]] || return

    out "v${tag}"

}

name () {

    local name="${1:-}"

    [[ -n "${name}" ]] || name="$(repo 2>/dev/null)" || name="$(basename -- "$(pwd -P)")"

    name="${name%/}"
    name="${name##*/}"

    [[ -n "${name}" ]] || { err "Missing repository name"; return; }

    out "${name}"

}
status () {

    need git || return

    isrepo || { err "Not a git repository"; return; }

    git diff --quiet && git diff --cached --quiet && { succ "Clean"; return; }

    git status --short

}
diffs () {

    need git || return

    isrepo || { err "Not a git repository"; return; }
    local target="${1:-}" mode="${2:-}"

    shift >/dev/null 2>&1 || true
    [[ "${mode}" == --* ]] && { shift >/dev/null 2>&1 || true; }

    case "${target}" in
        ""|work|working|unstaged) git diff "$@" ;;
        staged|cached)            git diff --cached "$@" ;;
        head)                     git diff HEAD "$@" ;;
        stat|--stat)              git diff --stat "$@" ;;
        name|names|--name-only)   git diff --name-only "$@" ;;
        all)                      git diff "$@"; git diff --cached "$@" ;;
        *)                        git diff "${target}" "$@" ;;
    esac

}

owner () {

    need gh || return

    local name="${1:-}" owner=""

    if [[ -n "${name}" ]]; then
        name="$(repo "${name}")" || return
        owner="${name%%/*}"
    else
        owner="$(gh api user -q .login 2>/dev/null)" || { err "Failed to detect GitHub user"; return; }
    fi

    [[ -n "${owner}" ]] || owner="${GITHUB_OWNER:-}"
    [[ -n "${owner}" ]] || { err "Failed to detect GitHub owner"; return; }

    out "${owner}"

}
login () {

    need gh || return
    gh auth login "$@"

}
logout () {

    need gh || return
    gh auth logout "$@"

}
token () {

    need gh || return
    gh auth token "$@"

}
