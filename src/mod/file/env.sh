
envfile () {

    local mode="${1:-}" file="${2:-}" type="${3:-env}" root="" f="" t=""
    local -a list=() types=()

    root="$(git rev-parse --show-toplevel 2>/dev/null || printf '%s' "${PWD:-.}")"

    [[ -n "${file}" && ! -f "${file}" && -f "${root}/${file}" ]] && file="${root}/${file}"

    case "${mode}" in
        pro*) list=( production prod pro "" ) ;;
        st*)  list=( st sta stag stage "" pro prod production ) ;;
        *)    list=( "" local dev st sta stag stage pro prod production ) ;;
    esac
    case "${type}" in
        sec*) types=( secrets secret sec ) ;;
        var*) types=( vars var variables variable ) ;;
        *)    types=( env envs vars var variables variable secrets secret sec ) ;;
    esac

    if [[ ! -f "${file}" ]]; then

        for t in "${types[@]}"; do

            for f in "${list[@]}"; do

                if [[ -z "${f}" ]]; then

                    [[ -f "${root}/.${t}" ]] && { file="${root}/.${t}"; break 2; }
                    [[ -f "${root}/${t}"  ]] && { file="${root}/${t}";  break 2; }

                    [[ -f ".${t}" ]] && { file=".${t}"; break 2; }
                    [[ -f "${t}"  ]] && { file="${t}";  break 2; }

                else

                    [[ -f "${root}/.${t}.${f}" ]] && { file="${root}/.${t}.${f}"; break 2; }
                    [[ -f "${root}/${t}.${f}"  ]] && { file="${root}/${t}.${f}";  break 2; }
                    [[ -f "${root}/.${f}.${t}" ]] && { file="${root}/.${f}.${t}"; break 2; }
                    [[ -f "${root}/${f}.${t}"  ]] && { file="${root}/${f}.${t}";  break 2; }

                    [[ -f ".${t}.${f}" ]] && { file=".${t}.${f}"; break 2; }
                    [[ -f "${t}.${f}"  ]] && { file="${t}.${f}";  break 2; }
                    [[ -f ".${f}.${t}" ]] && { file=".${f}.${t}"; break 2; }
                    [[ -f "${f}.${t}"  ]] && { file="${f}.${t}";  break 2; }

                fi

            done

        done

    fi

    [[ -f "${file}" ]] || { err "Missing ${type} file"; return 1; }
    out "${file}"

}
varfile () {

    envfile "${1:-}" "${2:-}" variable

}
secfile () {

    envfile "${1:-}" "${2:-}" secret

}
