
syncdir () {

    need rsync || return

    local src="" dst="" dry=0 name="" bname="" ignore="" arg=""
    local -a args=() extra=() includes=() excludes=( .git )

    while (( $# )); do

        arg="${1:-}"

        case "${arg}" in
            -s|--src|--source)  src="${2:-}"; shift ;;
            -d|--dir|--dest)    dst="${2:-}"; shift ;;
            -n|--dry|--dry-run) dry="1" ;;
            -x|--exclude)       extra+=( "${2:-}" ); shift; ;;
            --)                 shift; extra+=( "$@" ); break ;;
            -*)                 extra+=( "${arg}" ) ;;
            *)
                if [[ -z "${src}" ]]; then src="${arg}"
                elif [[ -z "${dst}" ]]; then dst="${arg}"
                else extra+=( "${arg}" )
                fi
            ;;
        esac

        shift >/dev/null 2>&1 || true

    done

    [[ -d "${src}" ]] || src="$(git rev-parse --show-toplevel 2>/dev/null || printf '%s' "${PWD:-.}")"
    [[ -d "${src}" ]] || { err "Missing source dir: ${src}"; return; }

    if [[ -z "${dst}" ]]; then

        name="$(basename "$(cd "${src}" && pwd)")"

        if [[ "${SYNC_CAP:-}" == "1" ]]; then bname="$(cap "${name}")" || return
        else bname="${name}"
        fi

        dst="${SYNC_DIR:-${PWD:-.}}/${bname}"

    fi

    (( dry )) || mkdir -p "${dst}" || { err "Failed to create dir: ${dst}"; return; }

    while IFS= read -r ignore; do

        [[ -n "${ignore}" ]] || continue

        case "${ignore}" in
            "!"*) includes+=( "${ignore#!}" ) ;;
            *)    excludes+=( "${ignore}" ) ;;
        esac

    done < <(ignores)

    for ignore in "${extra[@]}"; do

        [[ -n "${ignore}" ]] || continue

        case "${ignore}" in
            "!"*) includes+=( "${ignore#!}" ) ;;
            *)    excludes+=( "${ignore}" ) ;;
        esac

    done

    for ignore in "${includes[@]}"; do args+=( --include="${ignore}" ); done
    for ignore in "${excludes[@]}"; do args+=( --exclude="${ignore}" ); done

    (( ${#includes[@]} )) && args+=( --include="*/" )

    if (( dry )); then

        command rsync -aznci --delete "${args[@]}" "${src%/}/" "${dst%/}/" \
            || { err "Failed to compare: ${src} <-> ${dst}"; return; }

        return

    fi

    command rsync -azP --delete "${args[@]}" "${src%/}/" "${dst%/}/" >/dev/null 2>&1 \
        || { err "Failed to sync: ${src} -> ${dst}"; return; }

    succ "Synced -> ${dst}"

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
