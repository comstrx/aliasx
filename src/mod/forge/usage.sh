
usage () {

    local bin="${1:-}" kind="" exe="" arg="" out=""

    [[ -n "${bin}" ]] || { err "Usage: usage <tool>"; return; }

    kind="$(type -t "${bin}" 2>/dev/null || true)"

    case "${kind}" in
        builtin|keyword)
            builtin help "${bin}" 2>/dev/null && return
        ;;
        function|alias)
            err "Cannot show help for shell ${kind}: ${bin}"
            return
        ;;
    esac

    exe="$(type -P "${bin}" 2>/dev/null || true)"

    [[ -n "${exe}" ]] || { err "Missing: ${bin}"; return; }

    for arg in --help help -h -?; do

        out="$(PAGER=cat MANPAGER=cat GIT_PAGER=cat command "${exe}" "${arg}" </dev/null 2>&1 || true)"

        [[ -n "${out}" ]] || continue

        case "${out}" in
            *[Uu]sage*|*[Oo]ptions*|*[Cc]ommands*|*[Hh]elp*)
                out "${out}"
                return
            ;;
        esac

    done

    if has man; then

        out="$(PAGER=cat MANPAGER=cat man "${bin}" </dev/null 2>/dev/null || true)"

        [[ -n "${out}" ]] && { out "${out}"; return; }

    fi

    err "Cannot show help for: ${bin}"

}
