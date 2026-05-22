
repo-info () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return

    gh repo view "${name}" \
        --json \
            nameWithOwner,description,url,visibility,isPrivate,isFork,isArchived,stargazerCount,forkCount,\
            openGraphImageUrl,createdAt,updatedAt,pushedAt,defaultBranchRef,licenseInfo \
        "$@" 2>/dev/null \
        || { err "Failed to get repository info: ${name}"; return; }

}
repo-health () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return

    gh repo view "${name}" \
        --json \
            nameWithOwner,description,url,visibility,isPrivate,isFork,\
            isArchived,stargazerCount,forkCount,\
            createdAt,updatedAt,pushedAt,defaultBranchRef,licenseInfo \
        "$@" 2>/dev/null \
        || { err "Failed to get repository health: ${name}"; return; }

}
repo-url () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return

    gh repo view "${name}" --json url -q '.url' "$@" 2>/dev/null \
        || { err "Failed to get repository url: ${name}"; return; }

}
repo-readme () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return

    gh api "repos/${name}/readme" --jq '.html_url' "$@" 2>/dev/null \
        || { err "README not found: ${name}"; return; }

}
repo-license () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return

    gh repo view "${name}" --json licenseInfo -q '.licenseInfo // empty' "$@" 2>/dev/null \
        || { err "Failed to get license: ${name}"; return; }

}
repo-license-name () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return

    gh repo view "${name}" --json licenseInfo -q '.licenseInfo.name // empty' "$@" 2>/dev/null \
        || { err "Failed to get license: ${name}"; return; }

}

disc-list () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return

    gh api graphql \
        -f owner="${name%/*}" \
        -f repo="${name##*/}" \
        -f query='
            query($owner: String!, $repo: String!) {
                repository(owner: $owner, name: $repo) {
                    discussions(first: 100, orderBy: {field: UPDATED_AT, direction: DESC}) {
                        nodes {
                            number
                            title
                            url
                            createdAt
                            updatedAt
                            author { login }
                            category { name }
                        }
                    }
                }
            }
        ' \
        --jq '.data.repository.discussions.nodes[] | "\(.number)	\(.title)	\(.url)"' \
        "$@"

}
collab-list () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return

    gh api "repos/${name}/collaborators" --paginate -q '.[].login' "$@"

}
contrib-list () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return

    gh api "repos/${name}/contributors" --paginate -q '.[].login' "$@"

}
language-list () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return

    gh api "repos/${name}/languages" "$@" 2>/dev/null \
        || { err "Failed to list languages: ${name}"; return; }

}
topic-list () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return

    gh api "repos/${name}/topics" --jq '.names[]?' "$@" 2>/dev/null \
        || { err "Failed to list topics: ${name}"; return; }

}
star-list () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return
    gh api "repos/${name}/stargazers" --paginate "$@"

}
view-list () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return

    gh api "repos/${name}/traffic/views" "$@" 2>/dev/null \
        || { err "Failed to list views. Requires repository access."; return; }

}

discs () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return

    gh api graphql \
        -f owner="${name%/*}" \
        -f repo="${name##*/}" \
        -f query='
            query($owner: String!, $repo: String!) {
                repository(owner: $owner, name: $repo) {
                    discussions {
                        totalCount
                    }
                }
            }
        ' \
        --jq '.data.repository.discussions.totalCount' \
        "$@"

}
collabs () {

    local out=""

    out="$(collab-list "$@")" || return
    printf '%s\n' "${out}" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' '

}
contribs () {

    local out=""

    out="$(contrib-list "$@")" || return
    printf '%s\n' "${out}" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' '

}
languages () {

    language-list "$@"

}
topics () {

    local out=""

    out="$(topic-list "$@")" || return
    [[ -n "${out}" ]] || { out 0; return; }

    printf '%s\n' "${out}" | wc -l | tr -d ' '

}
stars () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return
    gh repo view "${name}" --json stargazerCount -q '.stargazerCount' "$@"

}
views () {

    view-list "$@" --jq '.count'

}
