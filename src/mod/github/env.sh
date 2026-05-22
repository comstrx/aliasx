
env-exists () {

    need gh || return

    local name="${1:-}" repo_name=""
    shift >/dev/null 2>&1 || true

    [[ -n "${name}" ]] || { err "Missing environment name"; return; }

    repo_name="$(repo)" || return

    gh api "repos/${repo_name}/environments/${name}" "$@" >/dev/null 2>&1

}
find-env () {

    need gh || return

    local name="${1:-}" repo_name="" found=""
    shift >/dev/null 2>&1 || true

    [[ -n "${name}" ]] || { err "Missing environment name"; return; }

    repo_name="$(repo)" || return

    found="$(gh api "repos/${repo_name}/environments/${name}" --jq '.name' "$@" 2>/dev/null)" \
        || { err "Environment not found: ${name}"; return; }

    succ "Environment: ${found}"

}

new-env () {

    need gh || return

    local name="${1:-}" repo_name=""
    shift >/dev/null 2>&1 || true

    [[ -n "${name}" ]] || { err "Missing environment name"; return; }

    repo_name="$(repo)" || return

    gh api --method PUT "repos/${repo_name}/environments/${name}" "$@" >/dev/null 2>&1 \
        || { err "Failed to create environment: ${name}"; return; }

    succ "Environment created: ${name}"

}
del-env () {

    need gh || return

    local name="${1:-}" repo_name=""
    shift >/dev/null 2>&1 || true

    [[ -n "${name}" ]] || { err "Missing environment name"; return; }

    repo_name="$(repo)" || return

    gh api --method DELETE "repos/${repo_name}/environments/${name}" "$@" >/dev/null 2>&1 \
        || { err "Failed to delete environment: ${name}"; return; }

    succ "Environment deleted: ${name}"

}

env-list () {

    need gh || return

    local repo_name=""
    repo_name="$(repo)" || return

    gh api "repos/${repo_name}/environments" -q '.environments[].name' "$@" 2>/dev/null \
        || { err "Failed to list environments: ${repo_name}"; return; }

}
