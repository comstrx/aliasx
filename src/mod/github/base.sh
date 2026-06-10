
isrepo () {

    need git || return
    git rev-parse --is-inside-work-tree >/dev/null 2>&1

}
rroot () {

    local dir=""

    dir="$(git rev-parse --show-toplevel 2>/dev/null)" && { out "${dir}"; return; }
    out "$(root)"

}
cdrepo () {

    cd "$(rroot)" || { err "cannot cd repo root"; return; }

}
repo () {

    need gh || return

    local name="${1:-}" login="" url=""

    if [[ -z "${name}" ]]; then

        url="$(git config --get remote.origin.url 2>/dev/null)"

        login="${url%.git}"
        login="${login#*github.com[:/]}"

        [[ "${login}" == */* && "${login}" != *:* ]] && { out "${login}"; return; }

        login="$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null)" \
            || { err "Failed to detect current repository"; return; }

        [[ -n "${login}" ]] || { err "Failed to detect current repository"; return; }

        out "${login}"
        return

    fi

    [[ "${name}" == */* ]] && { out "${name}"; return; }

    login="$(gh api user -q .login 2>/dev/null)" || { err "Failed to detect GitHub user"; return; }
    [[ -n "${login}" ]] || { err "Failed to detect GitHub user"; return; }

    out "${login}/${name}"

}

branch () {

    need git || return

    git branch --show-current 2>/dev/null || { err "Failed to detect current branch"; return; }

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
    local target="${1:-}"

    shift >/dev/null 2>&1 || true

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
    name="$(repo "${name}" 2>/dev/null)" && owner="${name%%/*}"

    [[ -n "${owner}" ]] || owner="${GITHUB_OWNER:-}"
    [[ -n "${owner}" ]] || owner="$(gh api user -q .login 2>/dev/null || true)"
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
