
syncdir () {

    need rsync || return

    local src="${1:-}" dst="${2:-}" dry="${3:-}" name="" bname="" ignore=""
    local -a args=() excludes=( .git )

    [[ -d "${src}" ]] || src="$(git rev-parse --show-toplevel 2>/dev/null || printf '%s' "${PWD:-.}")"
    [[ -d "${src}" ]] || { err "Missing source dir: ${src}"; return; }

    if [[ -z "${dst}" ]]; then

        name="$(basename "$(cd "${src}" && pwd)")"

        if [[ "${SYNC_CAP:-}" == "1" ]]; then bname="$(cap "${name}")" || return
        else bname="${name}"
        fi

        dst="${SYNC_DIR:-${PWD:-.}}/${bname}"

    fi

    mkdir -p "${dst}" || { err "Failed to create dir: ${dst}"; return; }

    case "$(lower "${dry}")" in
        1|true|yes|y|--yes|-y|dry|dry-run|--dry|--dry-run) dry=1; shift 3 2>/dev/null || true ;;
        *) dry=0; shift 2 2>/dev/null || true ;;
    esac

    while IFS= read -r ignore; do
        [[ -n "${ignore}" ]] && excludes+=( "${ignore}" )
    done < <(ignores)

    for ignore in "$@"; do
        [[ -n "${ignore}" ]] && excludes+=( "${ignore}" )
    done
    for ignore in "${excludes[@]}"; do
        args+=( --exclude="${ignore}" )
    done

    if (( dry )); then

        command rsync -aznci --delete "${args[@]}" "${src%/}/" "${dst%/}/" \
            || { err "Failed to compare: ${src} <-> ${dst}"; return; }

        return

    fi

    command rsync -azP --delete "${args[@]}" "${src%/}/" "${dst%/}/" >/dev/null 2>&1 \
        || { err "Failed to sync: ${src} -> ${dst}"; return; }

    succ "Synced: ${src} -> ${dst}"

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
    return 1

}
