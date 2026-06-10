
backup () {

    need zip || return

    local src="" dir="" name="" base="" bname="" root="" dest="" last="" ignore="" arg=""
    local -a args=() extra=() excludes=( .git )

    while (( $# )); do

        arg="${1:-}"

        case "${arg}" in
            -s|--src|--source) src="${2:-}"; shift ;;
            -d|--dir|--dest)   dir="${2:-}"; shift ;;
            -n|--name)         name="${2:-}"; shift ;;
            -x|--exclude)      extra+=( "${2:-}" ); shift; ;;
            --)                shift; extra+=( "$@" ); break ;;
            -*)                extra+=( "${arg}" ) ;;
            *)
                if [[ -z "${src}" ]]; then src="${arg}"
                elif [[ -z "${dir}" ]]; then dir="${arg}"
                elif [[ -z "${name}" ]]; then name="${arg}"
                else extra+=( "${arg}" )
                fi
            ;;
        esac

        shift >/dev/null 2>&1 || true

    done

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

    else

        last="$(find "${root}" -maxdepth 1 -type f -name '*.zip' 2>/dev/null \
            | sed 's#.*/##' | grep -E '^[0-9]+\.zip$' | sed 's/\.zip$//' | sort -n | tail -n 1)"

        [[ -n "${last}" ]] && name="$((last + 1)).zip" || name="1.zip"

        dest="${root}/${name}"

    fi

    while IFS= read -r ignore; do

        [[ -n "${ignore}" ]] || continue
        [[ "${ignore}" == "!"* ]] && continue

        excludes+=( "${ignore}" )

    done < <(ignores)

    for ignore in "${extra[@]}"; do

        [[ -n "${ignore}" ]] || continue
        [[ "${ignore}" == "!"* ]] && continue

        excludes+=( "${ignore}" )

    done
    for ignore in "${excludes[@]}"; do

        if [[ "${ignore}" == /* ]]; then

            ignore="${ignore#/}"
            args+=( -x "${base}/${ignore}" -x "${base}/${ignore%/}/*" )

        else

            args+=( -x "${base}/${ignore}" -x "${base}/${ignore%/}/*" )
            args+=( -x "${base}/*/${ignore}" -x "${base}/*/${ignore%/}/*" )

        fi

    done

    ( cd "$(dirname -- "${src}")" && command zip -rq "${dest}" "${base}" "${args[@]}" ) \
        || { err "Failed to Archive: ${dest}"; return; }

    succ "Archived -> ${dest}"

}
