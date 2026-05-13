
SYNC_DIR="${SYNC_DIR:-/mnt/d/Projects}"
ARCHIVE_DIR="${ARCHIVE_DIR:-/mnt/d/Archive}"

syncdir () {

    ensure rsync || return

    local src="${1:-}" dst="${2:-}" dry="${3:-}" name="" ignore=""
    local -a args=() excludes=( .git )

    [[ -d "${src}" ]] || src="$(git rev-parse --show-toplevel 2>/dev/null || printf '%s' "${PWD:-.}")"
    [[ -d "${src}" ]] || { err "Missing source dir: ${src}"; return; }
    [[ -n "${dst}" ]] || { name="$(basename "$(cd "${src}" && pwd)")"; dst="${SYNC_DIR:-${PWD:-.}}/${name^}"; }

    mkdir -p "${dst}" || { err "Failed to create dir: ${dst}"; return; }

    case "${dry,,}" in
        1|true|yes|y|--yes|-y|dry|dry-run|--dry|--dry-run) dry=1; shift 3 2>/dev/null || true ;;
        *) dry=0; shift 2 2>/dev/null || true ;;
    esac

    while IFS= read -r ignore; do
        [[ -n "${ignore}" ]] && excludes+=( "${ignore}" )
    done < <(ignores)

    for ignore in "$@"; do [[ -n "${ignore}" ]] && excludes+=( "${ignore}" ); done
    for ignore in "${excludes[@]}"; do args+=( --exclude="${ignore}" ); done

    if (( dry )); then

        command rsync -aznci --delete "${args[@]}" "${src%/}/" "${dst%/}/" \
            || { err "Failed to compare: ${src} <-> ${dst}"; return; }

        return

    fi

    command rsync -azP --delete "${args[@]}" "${src%/}/" "${dst%/}/" >/dev/null 2>&1 \
        || { err "Failed to sync: ${src} -> ${dst}"; return; }

    succ "Synced ${src} -> ${dst}"

}
diffdir () {

    local src="${1:-}" dst="${2:-}"
    shift 2 2>/dev/null || true

    syncdir "${src}" "${dst}" --dry-run "$@"

}
synced () {

    local out=""

    out="$(diffdir "$@" 2>/dev/null)" || return
    [[ -z "${out//[[:space:]]/}" ]] && { succ "Yes"; return; }

    warn "No"

}
backup () {

    ensure zip || return

    local src="${1:-}" dir="${2:-}" name="${3:-}" base="" root="" dest="" last="" ignore=""
    local -a args=() excludes=( .git )

    shift 3 2>/dev/null || true

    [[ -d "${src}" ]] || src="$(git rev-parse --show-toplevel 2>/dev/null || printf '%s' "${PWD:-.}")"
    [[ -d "${src}" ]] || { err "Missing source dir: ${src}"; return; }

    base="$(basename "$(cd "${src}" && pwd)")"
    root="${dir:-${ARCHIVE_DIR:-${PWD:-.}}/${base^}}"

    mkdir -p "${root}" || { err "Failed to create dir: ${root}"; return; }

    if [[ -n "${name}" ]]; then

        [[ "${name}" == *.zip ]] || name="${name}.zip"
        dest="${root}/${name}"

    elif [[ -z "${name}" ]]; then

        last="$(find "${root}" -maxdepth 1 -type f -name '*.zip' -printf '%f\n' 2>/dev/null \
            | grep -E '^[0-9]+\.zip$' | sed 's/\.zip$//' | sort -n | tail -n 1)"

        [[ -n "${last}" ]] && name="$((last + 1))" || name="1"
        [[ "${name}" == *.zip ]] || name="${name}.zip"

        dest="${root}/${name}"

    fi

    while IFS= read -r ignore; do
        [[ -n "${ignore}" ]] && excludes+=( "${ignore}" )
    done < <(ignores)

    for ignore in "$@"; do [[ -n "${ignore}" ]] && excludes+=( "${ignore}" ); done
    for ignore in "${excludes[@]}"; do args+=( -x "${base}/${ignore}" -x "${base}/${ignore%/}/*" ); done

    ( cd "$(dirname -- "${src}")" && command zip -rq "${dest}" "${base}" "${args[@]}" ) \
        || { err "Failed to Archive: ${dest}"; return; }

    succ "Archived: ${dest}"

}
