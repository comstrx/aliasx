
isrepo () {

    ensure git || return
    git rev-parse --is-inside-work-tree >/dev/null 2>&1

}
repo () {

    ensure gh || return

    local name="${1:-}" user=""

    if [[ -z "${name}" ]]; then

        gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || { err "Not a git repository"; return; }
        return 0

    fi

    [[ "${name}" == */* ]] && { out "${name}"; return; }

    user="$(gh api user -q .login 2>/dev/null)" || { err "Failed to detect Github user"; return; }
    [[ -n "${user}" ]] || { err "Failed to detect Github user"; return; }

    out "${user}/${name}"

}
root () {

    local dir="" marker=""

    local -a markers=(
        artisan
        composer.json
        Cargo.toml
        xmake.lua
        go.mod
        pyproject.toml
        requirements.txt
        CMakeLists.txt
        package.json
        bun.lock
        bun.lockb
        pom.xml
        build.gradle
        src/main.lua
        src/main.sh
        main.lua
        main.sh
        index.lua
        index.sh
        run.lua
        run.sh
    )

    dir="$(git rev-parse --show-toplevel 2>/dev/null)" && { out "${dir}"; return; }
    dir="$(pwd -P)"

    while [[ "${dir}" != "/" ]]; do

        for marker in "${markers[@]}"; do
            [[ -f "${dir}/${marker}" ]] && { out "${dir}"; return; }
        done

        dir="$(dirname -- "${dir}")"

    done

    out "$(pwd -P)"

}
cdroot () {

    cd "$(root)" || { err "cannot cd project root"; return; }

}
name () {

    local name="${1:-}"

    [[ -n "${name}" ]] || name="$(repo 2>/dev/null)" || name="$(basename -- "$(pwd -P)")"

    name="${name%/}"
    name="${name##*/}"

    [[ -n "${name}" ]] || { err "Missing repository name"; return; }

    out "${name}"

}
owner () {

    ensure gh || return

    local name="${1:-}" owner=""

    if [[ -n "${name}" ]]; then
        name="$(repo "${name}")" || return
        owner="${name%%/*}"
    else
        owner="$(gh api user -q .login 2>/dev/null)" || { err "Failed to detect GitHub user"; return; }
    fi

    [[ -n "${owner}" ]] || { err "Failed to detect GitHub owner"; return; }

    out "${owner}"

}
status () {

    ensure git || return

    isrepo || { err "Not a git repository"; return; }

    git diff --quiet && git diff --cached --quiet && { succ "Clean"; return; }
    git status --short

    err "Dirty"
    return

}
branch () {

    ensure git || return

    git branch --show-current 2>/dev/null || { err "Failed to detect current branch"; return; }

}
version () {

    local version="${1:-${VERSION:-${TAG:-${APP_VERSION:-}}}}"

    version="${version#v}"
    [[ -n "${version}" ]] || return

    out "${version}"

}
tag () {

    local tag="${1:-${TAG:-${VERSION:-${APP_TAG:-}}}}"

    tag="${tag#v}"
    [[ -n "${tag}" ]] || return

    out "v${tag}"

}

repo-exists () {

    ensure gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return
    gh repo view "${name}" "$@" >/dev/null 2>&1

}
find-repo () {

    ensure gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return
    gh repo view "${name}" "$@" >/dev/null 2>&1 && { succ "Repository: ${name}"; return; }

    err "Repository not found: ${name}"
    return

}
new-repo () {

    ensure gh || return

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

    ensure gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return

    gh repo delete "${name}" --yes "$@" >/dev/null 2>&1 \
        || { err "Failed to delete repository: ${name}"; return; }

    succ "Repository deleted: ${name}"

}
archive-repo () {

    ensure gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return

    gh repo archive "${name}" --yes "$@" >/dev/null 2>&1 \
        || { err "Failed to archive repository: ${name}"; return; }

    succ "Repository archived: ${name}"

}
unarchive-repo () {

    ensure gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return

    gh repo unarchive "${name}" --yes "$@" >/dev/null 2>&1 \
        || { err "Failed to unarchive repository: ${name}"; return; }

    succ "Repository unarchived: ${name}"

}
rename-repo () {

    ensure gh || return

    local old="${1:-}" new="${2:-}"
    shift 2 >/dev/null 2>&1 || true

    old="$(repo "${old}")" || return

    [[ -n "${new}" ]] || new="$(basename -- "$(root 2>/dev/null)")" || return
    [[ "${old##*/}" != "${new}" ]] || { err "New name and old name are the same"; return; }

    gh repo rename "${new}" --repo "${old}" --yes "$@" >/dev/null 2>&1 \
        || { err "Failed to rename repository: ${old} -> ${new}"; return; }

    succ "Repository renamed -> ${old%/*}/${new}"

}
repo-list () {

    ensure gh || return
    gh repo list --limit 100 "$@"

}

branch-exists () {

    ensure git || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${name}" ]] || { err "Missing branch name"; return; }

    git rev-parse --verify "refs/heads/${name}" "$@" >/dev/null 2>&1 \
        || git ls-remote --exit-code --heads origin "${name}" "$@" >/dev/null 2>&1

}
find-branch () {

    ensure git || return

    local query="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${query}" ]] || { err "Missing branch query"; return; }

    git branch --no-color --all --list "*${query}*" "$@"

}
new-branch () {

    ensure git || return

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

    ensure git || return

    local name="${1:-}" force="${2:-0}" current=""

    shift >/dev/null 2>&1 || true
    [[ $# -gt 0 ]] && { shift >/dev/null 2>&1 || true; }

    [[ -n "${name}" ]] || { err "Missing branch name"; return; }

    current="$(current-branch 2>/dev/null || true)"

    [[ "${name}" != "${current}" ]] || { err "Cannot delete current branch: ${name}"; return; }

    if bool "${force}" force f; then git branch -D "${name}" >/dev/null 2>&1 || true
    else git branch -d "${name}" >/dev/null 2>&1 || true
    fi

    git push origin --delete "${name}" "$@" >/dev/null 2>&1 || true

    succ "Branch deleted -> ${name}"

}
current-branch () {

    ensure git || return

    git branch --show-current "$@" 2>/dev/null \
        || { err "Failed to detect current branch"; return; }

}
switch-branch () {

    ensure git || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${name}" ]] || { err "Missing branch name"; return; }

    git switch "${name}" "$@" >/dev/null 2>&1 && { succ "Switched -> ${name}"; return; }

    git switch -c "${name}" --track "origin/${name}" "$@" >/dev/null 2>&1 \
        || { err "Failed to switch branch: ${name}"; return; }

    succ "Switched -> ${name}"

}
default-branch () {

    ensure gh || return

    local name=""
    name="$(repo)" || return

    gh repo view "${name}" --json defaultBranchRef -q '.defaultBranchRef.name' "$@" 2>/dev/null \
        || { err "Failed to detect default branch: ${name}"; return; }

}
set-default-branch () {

    ensure gh || return

    local name="${1:-}" repo_name=""
    shift >/dev/null 2>&1 || true

    [[ -n "${name}" ]] || { err "Missing branch name"; return; }

    repo_name="$(repo)" || return

    gh api --method PATCH "repos/${repo_name}" -f "default_branch=${name}" "$@" >/dev/null 2>&1 \
        || { err "Failed to set default branch: ${name}"; return; }

    succ "Default branch set -> ${name}"

}
branch-list () {

    ensure git || return
    git branch --no-color --all "$@"

}

tag-exists () {

    ensure git || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(tag "${name}")" || return
    git rev-parse -q --verify "refs/tags/${name}" "$@" >/dev/null 2>&1

}
find-tag () {

    ensure git || return

    local query="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${query}" ]] || { err "Missing tag query"; return; }

    git tag --list "*${query}*" "$@"

}
tag-released () {

    ensure gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(tag "${name}")" || return
    gh release view "${name}" "$@" >/dev/null 2>&1

}
tag-release () {

    ensure gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(tag "${name}")" || return

    gh release view "${name}" --json url -q '.url' "$@" 2>/dev/null \
        || { err "Release not found: ${name}"; return; }

}
new-tag () {

    ensure git || return

    local name="${1:-}" force="${2:-0}"

    shift >/dev/null 2>&1 || true
    [[ $# -gt 0 ]] && { shift >/dev/null 2>&1 || true; }

    name="$(tag "${name}")" || return

    if tag-exists "${name}"; then

        bool "${force}" force f || return 0

        git tag -d "${name}" >/dev/null 2>&1 || true
        git push origin --delete "${name}" "$@" >/dev/null 2>&1 || true

    fi

    git tag "${name}" >/dev/null 2>&1 || { err "Failed to create tag: ${name}"; return; }
    git push origin "${name}" "$@" >/dev/null 2>&1 || { err "Failed to push tag: ${name}"; return; }

    succ "Tag ready -> ${name}"

}
del-tag () {

    ensure git || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(tag "${name}")" || return

    git tag -d "${name}" >/dev/null 2>&1 || true
    git push origin --delete "${name}" "$@" >/dev/null 2>&1 || true

    succ "Tag deleted -> ${name}"

}
tag-list () {

    ensure git || return
    git tag --sort=-v:refname "$@"

}

env-exists () {

    ensure gh || return

    local name="${1:-}" repo_name=""
    shift >/dev/null 2>&1 || true

    [[ -n "${name}" ]] || { err "Missing environment name"; return; }

    repo_name="$(repo)" || return
    gh api "repos/${repo_name}/environments/${name}" "$@" >/dev/null 2>&1

}
find-env () {

    ensure gh || return

    local name="${1:-}" repo_name="" found=""
    shift >/dev/null 2>&1 || true

    [[ -n "${name}" ]] || { err "Missing environment name"; return; }

    repo_name="$(repo)" || return

    found="$(gh api "repos/${repo_name}/environments/${name}" --jq '.name' "$@" 2>/dev/null)" \
        || { err "Environment not found: ${name}"; return; }

    succ "Environment: ${found}"

}
new-env () {

    ensure gh || return

    local name="${1:-}" repo_name=""
    shift >/dev/null 2>&1 || true

    [[ -n "${name}" ]] || { err "Missing environment name"; return; }

    repo_name="$(repo)" || return

    gh api --method PUT "repos/${repo_name}/environments/${name}" "$@" >/dev/null 2>&1 \
        || { err "Failed to create environment: ${name}"; return; }

    succ "Environment created: ${name}"

}
del-env () {

    ensure gh || return

    local name="${1:-}" repo_name=""
    shift >/dev/null 2>&1 || true

    [[ -n "${name}" ]] || { err "Missing environment name"; return; }

    repo_name="$(repo)" || return

    gh api --method DELETE "repos/${repo_name}/environments/${name}" "$@" >/dev/null 2>&1 \
        || { err "Failed to delete environment: ${name}"; return; }

    succ "Environment deleted: ${name}"

}
env-list () {

    ensure gh || return

    local repo_name=""
    repo_name="$(repo)" || return

    gh api "repos/${repo_name}/environments" -q '.environments[].name' "$@" 2>/dev/null \
        || { err "Failed to list environments: ${repo_name}"; return; }

}

set-var () {

    ensure gh || return

    local name="${1:-}" value="${2:-}" encode="${3:-}" type="${4:-}"
    shift 2 >/dev/null 2>&1 || true

    case "${type,,}" in
        sec*) type="secret"; shift >/dev/null 2>&1 || true ;;
        var*) type="variable"; shift >/dev/null 2>&1 || true ;;
        *)    type="variable" ;;
    esac

    [[ -n "${name}"  ]] || { err "Missing ${type} key"; return; }
    [[ -n "${value}" ]] || { err "Missing ${type} value"; return; }

    case "${encode,,}" in
        --encode|--base64|--b64) encode=1; shift >/dev/null 2>&1 || true ;;
        --no-encode) encode=0; shift >/dev/null 2>&1 || true ;;
        *) encode=0;
    esac

    if (( encode )); then
        value="$(printf '%s' "${value}" | base64 | tr -d '\n')" || { err "Failed to encode value"; return; }
    fi

    printf '%s' "${value}" | gh "${type}" set "${name}" "$@" >/dev/null 2>&1 \
        || { err "Failed to add ${type}: ${name}"; return; }

    succ "${type^} added: ${name}"

}
get-var () {

    ensure gh || return

    local name="${1:-}" decode="${2:-}" type="${3:-}" value=""
    shift >/dev/null 2>&1 || true

    case "${type,,}" in
        sec*) type="secret"; shift >/dev/null 2>&1 || true ;;
        var*) type="variable"; shift >/dev/null 2>&1 || true ;;
        *)    type="variable" ;;
    esac

    [[ -n "${name}" ]] || { err "Missing ${type} key"; return; }

    case "${decode,,}" in
        --decode|--base64|--b64) decode=1; shift >/dev/null 2>&1 || true ;;
        --no-decode) decode=0; shift >/dev/null 2>&1 || true ;;
        *) decode=0 ;;
    esac

    if [[ "${type}" == "secret" ]]; then

        gh secret list "$@" 2>/dev/null | awk '{print $1}' | grep -Fxq -- "${name}" \
            || { err "Secret not found: ${name}"; return; }

        out "****"
        return

    fi

    value="$(gh variable get "${name}" --json value -q '.value' "$@" 2>/dev/null)" \
        || { err "Variable not found: ${name}"; return; }

    if (( decode )); then printf '%s' "${value}" | base64 -d; printf '\n'
    else out "${value}"
    fi

}
del-var () {

    ensure gh || return

    local name="${1:-}" type="${2:-}"
    shift >/dev/null 2>&1 || true

    case "${type,,}" in
        sec*) type="secret"; shift >/dev/null 2>&1 || true ;;
        var*) type="variable"; shift >/dev/null 2>&1 || true ;;
        *)    type="variable" ;;
    esac

    [[ -n "${name}" ]] || { err "Missing ${type} key"; return; }

    gh "${type}" delete "${name}" "$@" >/dev/null 2>&1 \
        || { err "Failed to delete ${type}: ${name}"; return; }

    succ "${type^} deleted: ${name}"

}
push-vars () {

    ensure gh || return

    local file="${1:-}" type="${2:-}"

    case "${type,,}" in
        sec*) type="secret"; shift >/dev/null 2>&1 || true ;;
        var*) type="variable"; shift >/dev/null 2>&1 || true ;;
        *)    type="variable" ;;
    esac

    if [[ "${file}" == --* ]]; then file=""
    else shift >/dev/null 2>&1 || true
    fi

    if [[ ! -f "${file}" ]]; then

        if [[ "${type}" == "secret" ]]; then file="$(secfile "${file}" 2>/dev/null || true)"
        else file="$(varfile "${file}" 2>/dev/null || true)"
        fi

        [[ -f "${file}" ]] || { err "Missing ${type}s file"; return; }

    fi

    gh "${type}" set -f "${file}" "$@" >/dev/null 2>&1 \
        || { err "Failed to set ${type}s: ${file}"; return; }

    succ "${type^}s pushed from: ${file}"

}
del-vars () {

    ensure gh || return

    local type="${1:-}" name=""
    local -a keys=()

    case "${type,,}" in
        sec*) type="secret"; shift >/dev/null 2>&1 || true ;;
        var*) type="variable"; shift >/dev/null 2>&1 || true ;;
        *)    type="variable" ;;
    esac

    mapfile -t keys < <(gh "${type}" list "$@" --json name -q '.[].name' 2>/dev/null)

    [[ "${#keys[@]}" -gt 0 ]] || { warn "No ${type}s found"; return; }

    for name in "${keys[@]}"; do

        [[ -n "${name}" ]] || continue

        gh "${type}" delete "${name}" "$@" >/dev/null 2>&1 \
            || { err "Failed to delete ${type}: ${name}"; return; }

    done

    succ "${type^}s deleted"

}
sync-vars () {

    ensure gh || return

    local file="${1:-}" type="${2:-}"

    case "${type,,}" in
        sec*) type="secret"; shift >/dev/null 2>&1 || true ;;
        var*) type="variable"; shift >/dev/null 2>&1 || true ;;
        *)    type="variable" ;;
    esac

    if [[ "${file}" == --* ]]; then file=""
    else shift >/dev/null 2>&1 || true
    fi

    if [[ ! -f "${file}" ]]; then

        if [[ "${type}" == "secret" ]]; then file="$(secfile "${file}" 2>/dev/null || true)"
        else file="$(varfile "${file}" 2>/dev/null || true)"
        fi

        [[ -f "${file}" ]] || { err "Missing ${type}s file"; return; }

    fi

    (
        local remote="" tmp_local="" tmp_remote="" tmp_delete=""

        tmp_local="$(mktemp)"  || { err "Failed to create temp file"; return; }
        tmp_remote="$(mktemp)" || { err "Failed to create temp file"; return; }
        tmp_delete="$(mktemp)" || { err "Failed to create temp file"; return; }

        trap 'rm -f "${tmp_local}" "${tmp_remote}" "${tmp_delete}"' EXIT

        awk -F= '
            { sub(/\r$/, ""); sub(/^[[:space:]]*export[[:space:]]+/, "") }
            /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
            /^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=/
            { key=$1; gsub(/^[[:space:]]+|[[:space:]]+$/, "", key); print key }
        ' "${file}" | sort -u > "${tmp_local}" || { err "Failed to parse local ${type}s file: ${file}"; return; }

        gh "${type}" set -f "${file}" "$@" >/dev/null 2>&1 \
            || { err "Failed to set ${type}s: ${file}"; return; }

        gh "${type}" list "$@" --json name -q '.[].name' 2>/dev/null | sort -u > "${tmp_remote}" \
            || { err "Failed to list ${type}s"; return; }

        comm -23 "${tmp_remote}" "${tmp_local}" > "${tmp_delete}" \
            || { err "Failed to compare ${type}s"; return; }

        while IFS= read -r remote; do

            [[ -n "${remote}" ]] || continue

            gh "${type}" delete "${remote}" "$@" >/dev/null 2>&1 \
                || { err "Failed to delete ${type}: ${remote}"; return; }

        done < "${tmp_delete}"

    ) || return

    succ "${type^}s synced from: ${file}"

}
var-list () {

    ensure gh || return

    local type="${1:-}"

    case "${type,,}" in
        sec*) type="secret"; shift >/dev/null 2>&1 || true ;;
        var*) type="variable"; shift >/dev/null 2>&1 || true ;;
        *)    type="variable" ;;
    esac

    gh "${type}" list "$@"

}

set-secret () {

    local name="${1:-}" value="${2:-}" encode="${3:-}"
    shift 2 >/dev/null 2>&1 || true

    case "${encode,,}" in
        --encode|--base64|--b64) shift >/dev/null 2>&1 || true ;;
        *) encode="--no-encode" ;;
    esac

    set-var "${name}" "${value}" "${encode}" secret "$@"

}
get-secret () {

    local name="${1:-}" decode="${2:-}"
    shift >/dev/null 2>&1 || true

    case "${decode,,}" in
        --decode|--base64|--b64) shift >/dev/null 2>&1 || true ;;
        *) decode="--no-decode" ;;
    esac

    get-var "${name}" "${decode}" secret "$@"

}
del-secret () {

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    del-var "${name}" secret "$@"

}
push-secrets () {

    local file="${1:-}"
    shift >/dev/null 2>&1 || true

    push-vars "${file}" secret "$@"

}
del-secrets () {

    del-vars secret "$@"

}
sync-secrets () {

    local file="${1:-}"
    shift >/dev/null 2>&1 || true

    sync-vars "${file}" secret "$@"

}
secret-list () {

    var-list secret "$@"

}

ssh-id () {

    ensure gh || return

    local key="${1:-}" id=""
    shift >/dev/null 2>&1 || true

    [[ -n "${key}" ]] || { err "Missing SSH key id/title"; return; }

    id="$(
        gh api user/keys --paginate \
            --jq ".[] | select((.id|tostring)==\"${key}\" or .title==\"${key}\") | .id" \
            "$@" 2>/dev/null | head -n 1
    )"

    [[ -n "${id}" ]] || { err "SSH key not found: ${key}"; return; }

    out "${id}"

}
ssh-exists () {

    ensure gh || return

    local key="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${key}" ]] || { err "Missing SSH key id/title"; return; }

    ssh-id "${key}" "$@" >/dev/null 2>&1

}
find-ssh () {

    ensure gh || return

    local key="${1:-}" id=""
    shift >/dev/null 2>&1 || true

    [[ -n "${key}" ]] || { err "Missing SSH key id/title"; return; }

    id="$(ssh-id "${key}" "$@")" || return

    gh api user/keys --paginate --jq ".[] | select((.id|tostring)==\"${id}\")" "$@" 2>/dev/null \
        || { err "SSH key not found: ${key}"; return; }

}
add-ssh () {

    ensure ssh-keygen || return
    ensure ssh-add    || return
    ensure gh         || return

    local name="${1:-id_ed25519}" email="${2:-}" force="${3:-0}" title="" key="" pub=""

    if bool "${name}" force f; then force=1; name=""
    elif bool "${email}" force f; then force=1; email=""
    elif bool "${force}" force f; then force=1
    else force=0
    fi

    name="${name:-id_ed25519}"
    key="${HOME}/.ssh/${name}"
    pub="${key}.pub"
    title="$(hostname)-${name}"

    mkdir -p -- "${HOME}/.ssh" || { err "Failed to create ~/.ssh"; return; }
    chmod 700 -- "${HOME}/.ssh" >/dev/null 2>&1 || true

    [[ -n "${email}" ]] || email="$(gh api user -q .email 2>/dev/null || true)"
    [[ -n "${email}" ]] || email="${USER}@$(hostname)"

    if [[ -f "${key}" || -f "${key}.pub" ]]; then

        (( force )) || { err "SSH key already exists: ${key}. Use force/-f to reset it."; return; }
        rm -f -- "${key}" "${pub}" >/dev/null 2>&1 || true

    fi

    ssh-keygen -t ed25519 -C "${email}" -f "${key}" -N "" >/dev/null 2>&1 \
        || { err "Failed to generate SSH key: ${key}"; return; }

    chmod 600 -- "${key}" >/dev/null 2>&1 || true
    chmod 644 -- "${pub}" >/dev/null 2>&1 || true

    [[ -n "${SSH_AUTH_SOCK:-}" ]] || { eval "$(ssh-agent -s)" >/dev/null 2>&1 || true; }

    ssh-add "${key}" >/dev/null 2>&1 || true

    gh ssh-key add "${pub}" --title "${title}" >/dev/null 2>&1 \
        || { err "Failed to add SSH key to GitHub"; return; }

    succ "SSH key added -> ${title}"

}
del-ssh () {

    ensure gh || return

    local key="${1:-}" id=""
    shift >/dev/null 2>&1 || true

    [[ -n "${key}" ]] || { err "Missing SSH key id/title"; return; }

    id="$(ssh-id "${key}" "$@")" || return

    gh ssh-key delete "${id}" --yes "$@" >/dev/null 2>&1 \
        || { err "Failed to delete SSH key: ${key}"; return; }

    succ "SSH key deleted -> ${key}"

}
ssh-list () {

    ensure gh || return
    gh api user/keys --paginate "$@"

}

run-list () {

    ensure gh || return
    gh run list "$@"

}
user-list () {

    ensure gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return
    gh api "repos/${name}/collaborators" -q '.[].login' "$@"

}
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

fork () {

    ensure gh || return

    local name="${1:-}" user="" fork=""
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return
    user="$(owner)" || return
    fork="${user}/${name##*/}"

    if repo-exists "${fork}"; then

        gh repo sync "${fork}" "$@" >/dev/null 2>&1 \
            || { err "Failed to sync fork: ${fork}"; return; }

        succ "Fork synced: ${fork}"
        return

    fi

    gh repo fork "${name}" --clone=false "$@" >/dev/null 2>&1 \
        || { err "Failed to fork repository: ${name}"; return; }

    succ "Repository forked: ${fork}"

}
clone () {

    ensure gh || return

    local name="${1:-}" dir="${2:-}"
    shift >/dev/null 2>&1 || true

    [[ "${dir}" == --* ]] && dir=""
    [[ -n "${dir}" ]] && { shift >/dev/null 2>&1 || true; }

    name="$(repo "${name}")" || return

    if [[ -n "${dir}" ]]; then

        gh repo clone "${name}" "${dir}" "$@" || { err "Failed to clone repository: ${name}"; return; }
        succ "Cloned: ${name} -> ${dir}"
        return

    fi

    gh repo clone "${name}" "$@" || { err "Failed to clone repository: ${name}"; return; }
    succ "Cloned: ${name}"

}
pull () {

    ensure git || return

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

    if [[ "${pull_out,,}" == *already\ up\ to\ date* || "${pull_out,,}" == *up-to-date* ]]; then succ "Up to date"
    else succ "Pulled"
    fi

}
init () {

    ensure git || return
    ensure gh  || return

    local name="" visibility="" create=1 remote="" arg=""
    local -a rest=()

    while (( $# )); do

        arg="${1:-}"

        case "${arg}" in
            -n|--name)
                shift
                [[ -n "${1:-}" ]] || { err "Missing name value"; return; }
                name="${1}"
            ;;
            --public|public)
                visibility="public"
            ;;
            --private|private)
                visibility="private"
            ;;
            --create|-c)
                create=1
            ;;
            --no-create|-no-c)
                create=0
            ;;
            --)
                shift
                rest+=( "$@" )
                break
            ;;
            -*)
                rest+=( "${arg}" )
            ;;
            *)
                if [[ -z "${name}" ]]; then name="${arg}"
                elif [[ -z "${visibility}" ]]; then visibility="${arg}"
                else rest+=( "${arg}" )
                fi
            ;;
        esac

        shift >/dev/null 2>&1 || true

    done

    [[ -n "${name}" ]] || name="$(basename -- "$(pwd -P)")"
    name="$(repo "${name}")" || return

    isrepo || git init >/dev/null 2>&1 || { err "Failed to initialize git repository"; return; }

    git branch -M main >/dev/null 2>&1 || true
    
    if (( create )); then

        new-repo "${name}" "${visibility}" "${rest[@]}" >/dev/null 2>&1 || return

        remote="$(gh repo view "${name}" --json sshUrl -q '.sshUrl' 2>/dev/null)" \
            || { err "Failed to detect repository remote"; return; }

        if git remote get-url origin >/dev/null 2>&1; then

            git remote set-url origin "${remote}" >/dev/null 2>&1 \
                || { err "Failed to update remote origin"; return; }

        else

            git remote add origin "${remote}" >/dev/null 2>&1 \
                || { err "Failed to add remote origin"; return; }

        fi

    fi

    succ "Repository initialized: ${name}"

}
push () {

    ensure git || return

    local msg="" tag="" branch="" do_backup=0 do_sync=0 force=0 arg="" push_out=""
    local -a rest=()

    while (( $# )); do

        arg="${1:-}"

        case "${arg}" in
            -m|--message)
                shift
                [[ -n "${1:-}" ]] || { err "Missing message value"; return; }
                msg="${1}"
            ;;
            -t|--tag)
                shift
                [[ -n "${1:-}" ]] || { err "Missing tag value"; return; }
                tag="${1}"
            ;;
            -b|--branch)
                shift
                [[ -n "${1:-}" ]] || { err "Missing branch value"; return; }
                branch="${1}"
            ;;
            -f|--force)
                force=1
                rest+=( --force )
            ;;
            --backup)
                do_backup=1
            ;;
            --sync)
                do_sync=1
            ;;
            --)
                shift
                rest+=( "$@" )
                break
            ;;
            -*)
                rest+=( "${arg}" )
            ;;
            *)
                if [[ -z "${msg}" ]]; then msg="${arg}"
                elif [[ -z "${tag}" ]]; then tag="${arg}"
                elif [[ -z "${branch}" ]]; then branch="${arg}"
                else rest+=( "${arg}" )
                fi
            ;;
        esac

        shift >/dev/null 2>&1 || true

    done

    isrepo || init "${rest[@]}" || return

    [[ -z "${tag}"    ]] || tag="$(tag "${tag}")" || return
    [[ -n "${branch}" ]] || branch="$(branch 2>/dev/null || true)"
    [[ -n "${branch}" ]] || branch="main"

    git branch -M "${branch}" >/dev/null 2>&1 || true
    git add . >/dev/null 2>&1 || { err "Failed to add ."; return; }

    if ! git rev-parse --verify HEAD >/dev/null 2>&1; then

        [[ -z "${msg}" && -n "${tag}" ]] && msg="Track Release: ${tag}"
        [[ -z "${msg}" ]] && msg="Initial Commit"

        if git diff --cached --quiet >/dev/null 2>&1; then
            git commit --allow-empty -m "${msg}" >/dev/null 2>&1 || { err "Failed to create initial commit"; return; }
        else
            git commit -m "${msg}" >/dev/null 2>&1 || { err "Failed to create initial commit"; return; }
        fi

    fi
    if ! git diff --cached --quiet >/dev/null 2>&1; then

        [[ -z "${msg}" && -n "${tag}" ]] && msg="Track Release: ${tag}"
        [[ -z "${msg}" && -z "${tag}" ]] && msg="New Commit"

        git commit -m "${msg}" >/dev/null 2>&1 || { err "Failed to commit"; return; }

    fi

    if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then

        push_out="$(git push "${rest[@]}" 2>&1)" \
            || { printf '%s\n' "${push_out}" >&2; err "Failed to push"; return; }

    else

        push_out="$(git push -u origin "${branch}" "${rest[@]}" 2>&1)" \
            || { printf '%s\n' "${push_out}" >&2; err "Failed to push"; return; }

    fi

    if [[ -n "${tag}" ]]; then

        new-tag "${tag}" "${force}" >/dev/null || return
        succ "Tag pushed: ${tag}"

    else

        if [[ "${push_out,,}" == *up-to-date* ]]; then succ "Up to date"
        else succ "Pushed"
        fi

    fi

    if (( do_sync )); then

        declare -F syncdir >/dev/null 2>&1 || return 0
        syncdir || return

    fi
    if (( do_backup )); then

        declare -F backup >/dev/null 2>&1 || return 0
        backup "" "" "${tag}" || return

    fi

    return 0

}
release () {

    ensure git || return
    ensure gh  || return

    local tag="" name="" bin="" title="" notes="" root="" dir="" file="" shaname="" sums="" arg="" url=""
    local -a rest=() args=() assets=() push_args=()

    while (( $# )); do

        arg="${1:-}"

        case "${arg}" in
            -t|--tag)
                shift
                [[ -n "${1:-}" ]] || { err "Missing tag value"; return; }
                tag="${1}"
            ;;
            -n|--name)
                shift
                [[ -n "${1:-}" ]] || { err "Missing name value"; return; }
                name="${1}"
            ;;
            -b|--bin)
                shift
                [[ -n "${1:-}" ]] || { err "Missing bin value"; return; }
                bin="${1}"
            ;;
            --title)
                shift
                [[ -n "${1:-}" ]] || { err "Missing title value"; return; }
                title="${1}"
            ;;
            --notes)
                shift
                [[ -n "${1:-}" ]] || { err "Missing notes value"; return; }
                notes="${1}"
            ;;
            --backup)
                push_args+=( --backup )
            ;;
            --sync)
                push_args+=( --sync )
            ;;
            --)
                shift
                rest+=( "$@" )
                break
            ;;
            -*)
                rest+=( "${arg}" )
            ;;
            *)
                if   [[ -z "${tag}"   ]]; then tag="${arg}"
                elif [[ -z "${name}"  ]]; then name="${arg}"
                elif [[ -z "${bin}"   ]]; then bin="${arg}"
                elif [[ -z "${title}" ]]; then title="${arg}"
                elif [[ -z "${notes}" ]]; then notes="${arg}"
                else rest+=( "${arg}" )
                fi
            ;;
        esac

        shift >/dev/null 2>&1 || true

    done

    tag="$(tag "${tag}")"      || return
    name="$(name "${name}")"   || return
    root="$(root 2>/dev/null)" || return

    tag-exists "${tag}" || push --tag "${tag}" "${push_args[@]}" || return

    [[ -n "${bin}" && ! -f "${bin}" && -f "${root}/${bin}" ]] && bin="${root}/${bin}"

    if [[ -n "${title}" ]]; then args+=( --title "${title}" )
    else args+=( --title "${name} ${tag}" )
    fi

    if [[ -f "${notes}" ]]; then args+=( --notes-file "${notes}" )
    elif [[ -n "${notes}" ]]; then args+=( --notes "${notes}" )
    elif [[ -f "${root}/CHANGELOG.md" ]]; then args+=( --notes-file "${root}/CHANGELOG.md" )
    else args+=( --generate-notes )
    fi

    if [[ -f "${bin}" ]]; then

        ensure sha256sum || return

        dir="$(dirname -- "${bin}")"
        file="$(basename -- "${bin}")"

        shaname="SHA256SUMS"
        sums="${dir}/${shaname}"

        (
            cd -- "${dir}" || exit 1
            sha256sum -- "${file}" > "${shaname}"        || exit 1
            sha256sum -c -- "${shaname}" >/dev/null 2>&1 || exit 1
        ) || { err "Failed to generate checksum"; return; }

        assets+=( "${bin}" "${sums}" )

    fi

    if tag-released "${tag}"; then

        gh release edit "${tag}" "${args[@]}" "${rest[@]}" >/dev/null 2>&1 \
            || { err "Failed to edit release: ${tag}"; return; }

        if (( ${#assets[@]} )); then

            gh release upload "${tag}" "${assets[@]}" --clobber >/dev/null 2>&1 \
                || { err "Failed to upload assets: ${tag}"; return; }

        fi

    else

        gh release create "${tag}" "${args[@]}" "${assets[@]}" --verify-tag "${rest[@]}" >/dev/null 2>&1 \
            || { err "Failed to release: ${tag}"; return; }

    fi

    url="$(gh release view "${tag}" --json url -q .url 2>/dev/null)" || true
    [[ -n "${url}" ]] || url="https://github.com/$(repo)/releases/tag/${tag}"

    succ "Released -> ${url}"

}
rollback () {

    ensure git || return

    local mode="" value="" target="" arg="" push_out="" branch="" force=0
    local -a rest=()

    while (( $# )); do

        arg="${1:-}"

        case "${arg}" in
            -n|--head)
                shift
                [[ -n "${1:-}" ]] || { err "Missing head value"; return; }
                mode="head"
                value="${1}"
            ;;
            -t|--tag)
                shift
                [[ -n "${1:-}" ]] || { err "Missing tag value"; return; }
                mode="tag"
                value="${1}"
            ;;
            -c|--commit)
                shift
                [[ -n "${1:-}" ]] || { err "Missing commit value"; return; }
                mode="commit"
                value="${1}"
            ;;
            -f|--force)
                force=1
            ;;
            --)
                shift
                rest+=( "$@" )
                break
            ;;
            -*)
                rest+=( "${arg}" )
            ;;
            *)
                if [[ -z "${mode}" ]]; then
                    [[ "${arg}" =~ ^[0-9]+$ ]] && mode="head" || mode="commit"
                    value="${arg}"
                else
                    rest+=( "${arg}" )
                fi
            ;;
        esac

        shift >/dev/null 2>&1 || true

    done

    isrepo || { err "Not a git repository"; return; }

    [[ -n "${mode}" ]] || { mode="head"; value="1"; }

    if (( ! force )); then

        if ! git diff --quiet || ! git diff --cached --quiet; then
            err "Working tree is dirty. Use --force to discard changes."
            return
        fi

    fi

    case "${mode}" in
        head)
            [[ "${value}" =~ ^[0-9]+$ ]] || { err "Invalid head value: ${value}"; return; }
            (( value > 0 )) || { err "Invalid head value: ${value}"; return; }
            target="HEAD~${value}"
        ;;
        tag)
            target="$(tag "${value}")" || return
        ;;
        commit)
            target="${value}"
        ;;
    esac

    git rev-parse --verify "${target}^{commit}" >/dev/null 2>&1 \
        || { err "Invalid rollback target: ${target}"; return; }

    git reset --hard "${target}" >/dev/null 2>&1 \
        || { err "Failed to rollback to: ${target}"; return; }

    if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then

        push_out="$(git push --force-with-lease "${rest[@]}" 2>&1)" \
            || { printf '%s\n' "${push_out}" >&2; err "Failed to push rollback"; return; }

    else

        branch="$(branch 2>/dev/null || true)"
        [[ -n "${branch}" ]] || branch="main"

        push_out="$(git push -u origin "${branch}" --force-with-lease "${rest[@]}" 2>&1)" \
            || { printf '%s\n' "${push_out}" >&2; err "Failed to push rollback"; return; }

    fi

    succ "Rolled back to: ${target}"

}
