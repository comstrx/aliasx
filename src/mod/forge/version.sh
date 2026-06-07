
version () {

    need-all grep sed || return

    local bin="${1:-}" exe="" arg="" out="" s="" v=""
    local major="" minor="" patch="" tail=""

    [[ -n "${bin}" ]] || { err "Usage: version <tool>"; return; }

    if [[ "${bin}" == */* || "${bin}" == *\\* ]]; then

        [[ -f "${bin}" && -x "${bin}" ]] || { err "Missing: ${bin}"; return; }
        exe="${bin}"

    else

        exe="$(type -P "${bin}" 2>/dev/null || true)"
        [[ -n "${exe}" ]] || { err "Missing: ${bin}"; return; }

    fi

    for arg in --version -version version -V -v; do

        out="$(env PAGER=cat MANPAGER=cat GIT_PAGER=cat "${exe}" "${arg}" </dev/null 2>&1 || true)"

        [[ -n "${out}" ]] || continue

        while IFS= read -r s; do

            [[ -n "${s}" ]] || continue

            if [[ "${s}" =~ ^([0-9]+)\.([0-9]+)(\.([0-9]+))?([.+_-][0-9A-Za-z][0-9A-Za-z.+_-]*)?$ ]]; then

                major="${BASH_REMATCH[1]}"
                minor="${BASH_REMATCH[2]}"
                patch="${BASH_REMATCH[4]:-0}"
                tail="${BASH_REMATCH[5]:-}"

                v="${major}.${minor}.${patch}"

                if [[ -n "${tail}" ]]; then

                    tail="${tail#[.+_-]}"
                    tail="$(printf '%s\n' "${tail}" | sed -E 's/[.+_-]+/./g; s/^\.+//; s/\.+$//')"

                    [[ -n "${tail}" ]] && v="${v}-${tail}"

                fi

                out "${v}"
                return

            fi

        done < <(
            printf '%s\n' "${out}" |
            LC_ALL=C grep -Eio '[0-9]+[.][0-9]+([.][0-9]+)?([.+_-][0-9A-Za-z][0-9A-Za-z.+_-]*)?' 2>/dev/null
        )

    done

    err "Cannot detect version of: ${bin}"

}
version-like () {

    local name="${1:-}" want="${2:-}" current="" raw="" i=0 want_major="" want_minor="" want_patch="" want_tail="" want_depth=0
    local cur_major="" cur_minor="" cur_patch="" cur_tail="" major="" minor="" patch="" tail="" depth=0

    [[ -n "${name}" && -n "${want}" ]] || { err "Usage: version-like <tool> <want>"; return; }

    current="$(version "${name}" 2>/dev/null || true)"
    [[ -n "${current}" ]] || return 1

    for raw in "${want}" "${current}"; do

        raw="${raw//$'\r'/}"
        raw="${raw//$'\n'/ }"
        raw="${raw#"${raw%%[![:space:]]*}"}"
        raw="${raw%"${raw##*[![:space:]]}"}"
        raw="${raw#==}"
        raw="${raw#=}"
        raw="${raw#v}"
        raw="${raw#V}"

        [[ "${raw}" =~ ^([0-9]+)([.]([0-9]+))?([.]([0-9]+))?([.+_-]([0-9A-Za-z][0-9A-Za-z.+_-]*))?$ ]] || return 1

        major="${BASH_REMATCH[1]}"
        minor="${BASH_REMATCH[3]:-}"
        patch="${BASH_REMATCH[5]:-}"
        tail="${BASH_REMATCH[7]:-}"

        depth=1
        [[ -n "${minor}" ]] && depth=2
        [[ -n "${patch}" ]] && depth=3

        major="$((10#${major}))"
        [[ -n "${minor}" ]] && minor="$((10#${minor}))"
        [[ -n "${patch}" ]] && patch="$((10#${patch}))"

        if [[ -n "${tail}" ]]; then
            tail="${tail#[.+_-]}"
            tail="$(printf '%s\n' "${tail}" | tr '[:upper:]_' '[:lower:].' | sed -E 's/[.+_-]+/./g; s/^\.+//; s/\.+$//')"
        fi

        if (( i == 0 )); then
            want_major="${major}"
            want_minor="${minor}"
            want_patch="${patch}"
            want_tail="${tail}"
            want_depth="${depth}"
        else
            cur_major="${major}"
            cur_minor="${minor}"
            cur_patch="${patch}"
            cur_tail="${tail}"
        fi

        i=$(( i + 1 ))

    done

    [[ "${want_major}" == "${cur_major}" ]] || return 1
    (( want_depth < 2 )) || { [[ "${want_minor}" == "${cur_minor}" ]] || return 1; }
    (( want_depth < 3 )) || { [[ "${want_patch}" == "${cur_patch}" ]] || return 1; }
    [[ -z "${want_tail}" ]] || { [[ "${want_tail}" == "${cur_tail}" ]] || return 1; }

}
