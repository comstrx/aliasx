
rollback () {

    need git || return

    local mode="" value="" target="" arg="" push_out="" branch="" force=0
    local -a rest=()

    while (( $# )); do

        arg="${1:-}"

        case "${arg}" in
            -n|--head)
                shift
                [[ -n "${1:-}" ]] || { err "Missing head value"; return; }
                mode="head"
                value="${1}"
            ;;
            -t|--tag)
                shift
                [[ -n "${1:-}" ]] || { err "Missing tag value"; return; }
                mode="tag"
                value="${1}"
            ;;
            -c|--commit)
                shift
                [[ -n "${1:-}" ]] || { err "Missing commit value"; return; }
                mode="commit"
                value="${1}"
            ;;
            -f|--force)
                force=1
            ;;
            --)
                shift
                rest+=( "$@" )
                break
            ;;
            -*)
                rest+=( "${arg}" )
            ;;
            *)
                if [[ -z "${mode}" ]]; then
                    [[ "${arg}" =~ ^[0-9]+$ ]] && mode="head" || mode="commit"
                    value="${arg}"
                else
                    rest+=( "${arg}" )
                fi
            ;;
        esac

        shift >/dev/null 2>&1 || true

    done

    isrepo || { err "Not a git repository"; return; }

    [[ -n "${mode}" ]] || { mode="head"; value="1"; }

    if (( ! force )); then

        if ! git diff --quiet || ! git diff --cached --quiet; then

            err "Working tree is dirty. Use --force to discard changes."
            return

        fi

    fi

    case "${mode}" in
        head)
            [[ "${value}" =~ ^[0-9]+$ ]] || { err "Invalid head value: ${value}"; return; }
            (( value > 0 )) || { err "Invalid head value: ${value}"; return; }
            target="HEAD~${value}"
        ;;
        tag)
            target="$(tag "${value}")" || return
        ;;
        commit)
            target="${value}"
        ;;
    esac

    git rev-parse --verify "${target}^{commit}" >/dev/null 2>&1 \
        || { err "Invalid rollback target: ${target}"; return; }

    git reset --hard "${target}" >/dev/null 2>&1 \
        || { err "Failed to rollback to: ${target}"; return; }

    if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then

        push_out="$(git push --force-with-lease "${rest[@]}" 2>&1)" \
            || { printf '%s\n' "${push_out}" >&2; err "Failed to push rollback"; return; }

    else

        branch="$(branch || true)"
        [[ -n "${branch}" ]] || branch="main"

        push_out="$(git push -u origin "${branch}" --force-with-lease "${rest[@]}" 2>&1)" \
            || { printf '%s\n' "${push_out}" >&2; err "Failed to push rollback"; return; }

    fi

    succ "Rolled back to: ${target}"

}
