
backup () {

    need zip || return

    local src="${1:-}" dir="${2:-}" name="${3:-}" base="" bname="" root="" dest="" last="" ignore=""
    local -a args=() excludes=( .git )

    shift 3 2>/dev/null || true

    [[ -d "${src}" ]] || src="$(git rev-parse --show-toplevel 2>/dev/null || printf '%s' "${PWD:-.}")"
    [[ -d "${src}" ]] || { err "Missing source dir: ${src}"; return; }

    base="$(basename "$(cd "${src}" && pwd)")" || return

    if [[ "${ARCHIVE_CAP:-}" == "1" ]]; then bname="$(cap "${base}")" || return
    else bname="${base}"
    fi

    root="${dir:-${ARCHIVE_DIR:-${PWD:-.}}/${bname}}"

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

    for ignore in "$@"; do
        [[ -n "${ignore}" ]] && excludes+=( "${ignore}" )
    done
    for ignore in "${excludes[@]}"; do
        args+=( -x "${base}/${ignore}" -x "${base}/${ignore%/}/*" )
    done

    (
        cd "$(dirname -- "${src}")" && command zip -rq "${dest}" "${base}" "${args[@]}"
    ) || { err "Failed to Archive: ${dest}"; return; }

    succ "Archived: ${dest}"

}
