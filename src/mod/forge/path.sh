
paths () {

    local bin="${1:-}" sep=":" dir="" ext="" entry="" real="" seen=""

    [[ -n "${bin}" ]] || { err "Usage: paths <tool>"; return; }
    [[ "${PATH:-}" == *";"* ]] && sep=";"

    if [[ "${bin}" == */* || "${bin}" == *\\* ]]; then

        [[ -f "${bin}" ]] || return 1

        case "${bin}" in
            *.exe|*.cmd|*.bat|*.ps1) ;;
            *) [[ -x "${bin}" ]] || return 1 ;;
        esac

        if has realpath; then command realpath -- "${bin}" 2>/dev/null && return; fi
        if has readlink; then command readlink -f -- "${bin}" 2>/dev/null && return; fi

        out "${bin}"
        return

    fi
    while IFS= read -r dir; do

        [[ -n "${dir}" ]] || continue

        for ext in "" ".exe" ".cmd" ".bat" ".ps1"; do

            entry="${dir%/}/${bin}${ext}"
            [[ -f "${entry}" ]] || continue

            case "${entry}" in
                *.exe|*.cmd|*.bat|*.ps1) ;;
                *) [[ -x "${entry}" ]] || continue ;;
            esac

            real="${entry}"

            if has realpath; then real="$(command realpath -- "${entry}" 2>/dev/null || printf '%s\n' "${entry}")"
            elif has readlink; then real="$(command readlink -f -- "${entry}" 2>/dev/null || printf '%s\n' "${entry}")"
            fi

            case "${seen}" in
                *$'\n'"${real}"$'\n'*) continue ;;
            esac

            seen="${seen}"$'\n'"${real}"$'\n'
            out "${real}"

        done

    done < <(command tr "${sep}" '\n' <<< "${PATH:-}")

    [[ -n "${seen}" ]]

}
path () {

    local bin="${1:-}" entry=""
    [[ -n "${bin}" ]] || { err "Usage: path <tool>"; return; }

    IFS= read -r entry < <(paths "${bin}" 2>/dev/null) || return
    [[ -n "${entry}" ]] || return 1

    out "${entry}"

}
