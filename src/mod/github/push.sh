
push () {

    need git || return

    local msg="" tag="" branch="" do_backup=0 do_sync=0 force=0 arg="" push_out=""
    local -a rest=()

    while (( $# )); do

        arg="${1:-}"

        case "${arg}" in
            -m|--message)
                shift
                [[ -n "${1:-}" ]] || { err "Missing message value"; return; }
                msg="${1}"
            ;;
            -t|--tag)
                shift
                [[ -n "${1:-}" ]] || { err "Missing tag value"; return; }
                tag="${1}"
            ;;
            -b|--branch)
                shift
                [[ -n "${1:-}" ]] || { err "Missing branch value"; return; }
                branch="${1}"
            ;;
            -f|--force)
                force=1
                rest+=( --force )
            ;;
            --backup)
                do_backup=1
            ;;
            --sync)
                do_sync=1
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
                if [[ -z "${msg}" ]]; then msg="${arg}"
                elif [[ -z "${tag}" ]]; then tag="${arg}"
                elif [[ -z "${branch}" ]]; then branch="${arg}"
                else rest+=( "${arg}" )
                fi
            ;;
        esac

        shift >/dev/null 2>&1 || true

    done

    isrepo || init "${rest[@]}" || return

    [[ -z "${tag}"    ]] || tag="$(tag "${tag}")" || return
    [[ -n "${branch}" ]] || branch="$(branch 2>/dev/null || true)"
    [[ -n "${branch}" ]] || branch="main"

    git branch -M "${branch}" >/dev/null 2>&1 || true

    git add . >/dev/null 2>&1 || { err "Failed to add ."; return; }

    if ! git rev-parse --verify HEAD >/dev/null 2>&1; then

        [[ -z "${msg}" && -n "${tag}" ]] && msg="Track Release: ${tag}"
        [[ -z "${msg}" ]] && msg="Initial Commit"

        if git diff --cached --quiet >/dev/null 2>&1; then
            git commit --allow-empty -m "${msg}" >/dev/null 2>&1 || { err "Failed to create initial commit"; return; }
        else
            git commit -m "${msg}" >/dev/null 2>&1 || { err "Failed to create initial commit"; return; }
        fi

    fi
    if ! git diff --cached --quiet >/dev/null 2>&1; then

        [[ -z "${msg}" && -n "${tag}" ]] && msg="Track Release: ${tag}"
        [[ -z "${msg}" && -z "${tag}" ]] && msg="New Commit"

        git commit -m "${msg}" >/dev/null 2>&1 || { err "Failed to commit"; return; }

    fi

    if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then

        push_out="$(git push "${rest[@]}" 2>&1)" || { printf '%s\n' "${push_out}" >&2; err "Failed to push"; return; }

    else

        push_out="$(git push -u origin "${branch}" "${rest[@]}" 2>&1)" || { printf '%s\n' "${push_out}" >&2; err "Failed to push"; return; }

    fi

    if [[ -n "${tag}" ]]; then

        new-tag "${tag}" "${force}" >/dev/null || return
        succ "Tag pushed: ${tag}"

    else

        if [[ "${push_out,,}" == *up-to-date* ]]; then succ "Up to date"
        else succ "Pushed"
        fi

    fi

    if (( do_sync )); then

        declare -F syncdir >/dev/null 2>&1 || return 0
        syncdir || return

    fi
    if (( do_backup )); then

        declare -F backup >/dev/null 2>&1 || return 0
        backup "" "" "${tag}" || return

    fi

    return 0

}
