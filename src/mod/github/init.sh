
init () {

    need git || return
    need gh  || return

    local name="" visibility="" create=0 remote="" arg=""
    local -a rest=()

    while (( $# )); do

        arg="${1:-}"

        case "${arg}" in
            -n|--name)
                shift
                [[ -n "${1:-}" ]] || { err "Missing name value"; return; }
                name="${1}"
            ;;
            --public|public)
                visibility="--public"
            ;;
            --private|private)
                visibility="--private"
            ;;
            --create|-c)
                create=1
            ;;
            --no-create|-no-c)
                create=0
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
                if [[ -z "${name}" ]]; then name="${arg}"
                elif [[ -z "${visibility}" ]]; then visibility="${arg}"
                else rest+=( "${arg}" )
                fi
            ;;
        esac

        shift >/dev/null 2>&1 || true

    done

    [[ -n "${name}" ]] || name="$(basename -- "$(pwd -P)")"
    [[ -n "${visibility}" ]] || visibility="--private"

    name="$(repo "${name}")" || return

    if ! isrepo; then
        git init >/dev/null 2>&1 || { err "Failed to initialize git repository"; return; }
        git branch -M main >/dev/null 2>&1 || true
    fi

    (( create )) && { new-repo "${name}" "${visibility}" "${rest[@]}" || return; }

    if repo-exists "${name}"; then

        remote="$(gh repo view "${name}" --json sshUrl -q '.sshUrl' 2>/dev/null)" \
            || { err "Failed to detect repository remote"; return; }

        if git remote get-url origin >/dev/null 2>&1; then
            git remote set-url origin "${remote}" >/dev/null 2>&1 || { err "Failed to update remote origin"; return; }
        else
            git remote add origin "${remote}" >/dev/null 2>&1 || { err "Failed to add remote origin"; return; }
        fi

    elif (( create )); then

        err "Repository was not created: ${name}"
        return

    else

        warn "Repository not found, remote skipped: ${name}"
        return

    fi

    succ "Initialized -> ${name}"

}
