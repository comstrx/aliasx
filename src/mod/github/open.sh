
open-ssh () {

    openurl "https://github.com/settings/keys" || { err "Failed to open SSH keys"; return; }

    succ "Opened SSH keys"

}
open-repo () {

    local name="${1:-}" url=""
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return
    url="https://github.com/${name}"

    repo-exists "${name}" || { err "Repository not found: ${name}"; return; }
    openurl "${url}" || { err "Failed to open repository: ${name}"; return; }

    succ "Opened repository: ${name}"

}
open-actions () {

    local name="${1:-}" url=""
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return
    url="https://github.com/${name}/actions"

    repo-exists "${name}" || { err "Repository not found: ${name}"; return; }
    openurl "${url}" || { err "Failed to open actions: ${name}"; return; }

    succ "Opened actions: ${name}"

}
open-settings () {

    local name="${1:-}" url=""
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return
    url="https://github.com/${name}/settings"

    repo-exists "${name}" || { err "Repository not found: ${name}"; return; }
    openurl "${url}" || { err "Failed to open settings: ${name}"; return; }

    succ "Opened settings: ${name}"

}
open-branch () {

    local name="${1:-}" repo_name="" url=""
    shift >/dev/null 2>&1 || true

    [[ -n "${name}" ]] || name="$(current-branch 2>/dev/null || true)"
    [[ -n "${name}" ]] || { err "Missing branch name"; return; }

    repo_name="$(repo)" || return
    url="https://github.com/${repo_name}/tree/${name}"

    branch-exists "${name}" || { err "Branch not found: ${name}"; return; }
    openurl "${url}" || { err "Failed to open branch: ${name}"; return; }

    succ "Opened branch: ${name}"

}
open-tag () {

    local name="${1:-}" repo_name="" url=""
    shift >/dev/null 2>&1 || true

    name="$(tag "${name}")" || return
    repo_name="$(repo)" || return

    url="https://github.com/${repo_name}/tree/${name}"

    tag-exists "${name}" || { err "Tag not found: ${name}"; return; }
    openurl "${url}" || { err "Failed to open tag: ${name}"; return; }

    succ "Opened tag: ${name}"

}
open-release () {

    local name="${1:-}" repo_name="" url=""
    shift >/dev/null 2>&1 || true

    name="$(tag "${name}")" || return
    repo_name="$(repo)" || return

    url="https://github.com/${repo_name}/releases/tag/${name}"

    tag-released "${name}" || { err "Release not found: ${name}"; return; }
    openurl "${url}" || { err "Failed to open release: ${name}"; return; }

    succ "Opened release: ${name}"

}
