
cache-list () {

    need gh || return

    gh cache list "$@"

}
delete-cache () {

    need gh || return

    local id="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${id}" ]] || { err "Missing cache id/key"; return; }

    gh cache delete "${id}" "$@" \
        || { err "Failed to delete cache: ${id}"; return; }

    succ "Cache deleted: ${id}"

}
clear-cache () {

    need gh || return

    local id="" out=""
    local -a ids=()

    out="$(gh cache list --limit 1000 --json id -q '.[].id' "$@")" \
        || { err "Failed to list caches"; return; }

    [[ -n "${out}" ]] || { warn "No caches found"; return; }

    mapfile -t ids <<< "${out}"

    for id in "${ids[@]}"; do

        [[ -n "${id}" ]] || continue

        gh cache delete "${id}" "$@" >/dev/null 2>&1 \
            || { err "Failed to delete cache: ${id}"; return; }

    done

    succ "Caches cleared"

}
