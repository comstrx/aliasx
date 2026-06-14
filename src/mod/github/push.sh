
push () {

    need git || return

    local msg="" tag="" branch="" arg="" push_out="" current=""
    local explicit_branch=0 do_backup=0 do_sync=0 force=0 unborn=0
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
                explicit_branch=1
            ;;
            -f|--force)
                force=1
                rest+=( --force )
            ;;
            -fl|--force-with-lease)
                force=1
                rest+=( --force-with-lease )
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
                elif [[ -z "${branch}" ]]; then branch="${arg}"; explicit_branch=1
                else rest+=( "${arg}" )
                fi
            ;;
        esac

        shift >/dev/null 2>&1 || true

    done

    if ! isrepo || ! git remote get-url origin >/dev/null 2>&1; then

        init "${rest[@]}" || return

    fi

    [[ -z "${tag}"    ]] || tag="$(tag "${tag}")" || return
    [[ -n "${branch}" ]] || branch="$(branch 2>/dev/null || true)"
    [[ -n "${branch}" ]] || branch="main"

    git rev-parse --verify HEAD >/dev/null 2>&1 || unborn=1
    current="$(git branch --show-current 2>/dev/null || true)"

    if (( explicit_branch || unborn )) && [[ "${current}" != "${branch}" ]]; then
        git branch -M "${branch}" >/dev/null 2>&1 || true
    fi

    git add -A >/dev/null 2>&1 || { err "Failed to add -A"; return; }

    if (( unborn )); then

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

    else

        if [[ "${push_out,,}" == *up-to-date* ]]; then succ "Up to date"
        else succ "Pushed -> $(repo)"
        fi

    fi

    if (( do_sync )); then

        declare -F syncdir >/dev/null 2>&1 || return 0
        syncdir || return

    fi
    if (( do_backup )); then

        declare -F backup >/dev/null 2>&1 || return 0
        backup --name "${tag}" || return

    fi

    return 0

}
