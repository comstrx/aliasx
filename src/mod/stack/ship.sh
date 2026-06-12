
fine () {

    sync-vars    >/dev/null 2>&1 || true
    sync-secrets >/dev/null 2>&1 || true

    push --sync "$@"

}
gone () {

    local rc=0

    fine "$@" || { rc=$?; warn "push failed — locking anyway"; }
    lockscreen || rc=1

    return "${rc}"

}
ship () {

    sync-vars    >/dev/null 2>&1 || true
    sync-secrets >/dev/null 2>&1 || true

    push --sync --backup "$@"

}
release () {

    sync-vars    >/dev/null 2>&1 || true
    sync-secrets >/dev/null 2>&1 || true

    new-release --sync --backup "$@"

}

fleet () {

    local source="" base="" mono="" arg="" sha="" tag="" msg="" root="" src="" dest="" dst="" target=""
    local org="" item="" ignore="" repo="" prefix="" dry=0 push=0 release=0 sync=0 backup=0 failures=0 failed=0

    local -a targets=() sync_repos=() push_repos=() roots=()
    local -a protected=() ignored=() rest=() args=()

    source="saasx"
    targets=( visax:bokesto zainx:zaindevsa-art:zainlak- )

    sync_repos=( infra engine server admin docs client mobile ) # remove 'docs client mobile' in production period
    push_repos=( infra engine server admin docs client mobile )

    roots=( ".gitignore" ".dockerignore" ".gitattributes" ".editorconfig" )
    protected+=( ".env" ".env.local" ".env.production" ".secret" ".secret.local" ".secret.production" "profiles" )

    mono="$(rroot)" || return 0
    base="$(dirname "${mono}")" || return 0

    [[ "$(basename "${mono}")" == "${source}" ]] || return 0

    while (( $# )); do

        arg="${1:-}"

        case "${arg}" in
            --dry|--dry-run) dry=1 ;;
            --push)          push=1 ;;
            --release)       release=1 ;;
            --sync)          sync=1 ;;
            --backup)        backup=1 ;;
            -t|--tag)        shift; tag="${1:-}" ;;
            --)              shift; rest+=( "$@" ); break ;;
            -*)              rest+=( "${arg}" ) ;;
            *)
                if   [[ -z "${msg}" ]]; then msg="${arg}"
                elif [[ -z "${tag}" ]]; then tag="${arg}"
                else rest+=( "${arg}" )
                fi
            ;;
        esac

        shift >/dev/null 2>&1 || true

    done

    tag="$(tag "${tag}")"

    sha="$(git -C "${mono}" rev-parse --short HEAD 2>/dev/null || true)"
    msg="${tag:+${tag}@}${sha:+${sha}@}commit"

    [[ -n "${tag}" ]] && rest+=( --tag "${tag}" )
    [[ -n "${msg}" ]] && rest+=( --message "${msg}" )

    (( dry )) && args+=( --dry-run )

    for target in "${targets[@]}"; do

        failed=0

        IFS=':' read -r dest org prefix _ <<< "${target}:"

        out "\n------------- ${dest} -------------\n"

        for item in "${sync_repos[@]}"; do

            src="${mono}/${item}"
            dst="${base}/${dest}/${item}"

            ignored=()

            [[ -d "${src}" ]] || continue

            for ignore in "${protected[@]}"; do
                [[ -e "${dst}/${ignore#/}" || -L "${dst}/${ignore#/}" ]] && ignored+=( "/${ignore#/}" )
            done
            for root in "${roots[@]}"; do
                [[ -e "${src}/${root#/}" || -L "${src}/${root#/}" ]] || ignored+=( "/${root#/}" )
            done

            syncdir "${src}" "${dst}" "${args[@]}" "${ignored[@]}" || { failed=1; failures=$(( failures + 1 )); continue; }

        done
        for item in "${push_repos[@]}"; do

            src="${mono}/${item}"
            dst="${base}/${dest}/${item}"

            if [[ -d "${src}" && ! -e "${dst}" && " ${sync_repos[*]} " != *" ${item} "* ]]; then

                syncdir "${src}" "${dst}" "${args[@]}" || { failed=1; failures=$(( failures + 1 )); continue; }

            fi
            if (( ! dry )); then

                for root in "${roots[@]}"; do

                    [[ -d "${dst}" && -e "${mono}/${root#/}" && ! -e "${dst}/${root#/}" ]] || continue

                    cp -a -- "${mono}/${root#/}" "${dst}/${root#/}" || { failed=1; failures=$(( failures + 1 )); continue; }

                done

            fi

        done

        if (( ! dry && ! failed )); then

            (

                cd "${base}/${dest}" || exit 1

                (( sync || backup )) && out ""

                (( sync ))   && { syncdir || exit 1; }
                (( backup )) && { backup --name "${tag}" || exit 1; }

                exit 0

            ) || { failures=$(( failures + 1 )); continue; }

            if (( push )); then

                out ""

                for item in "${push_repos[@]}"; do

                    dst="${base}/${dest}/${item}"
                    repo="${org}/${prefix}${item}"

                    [[ -d "${dst}" ]] || continue

                    (

                        cd "${dst}" || exit 1

                        if ! isrepo && [[ -n "${org}" ]]; then init "${repo}" || exit 1
                        elif ! isrepo; then exit 0
                        fi

                        sync-vars    >/dev/null 2>&1 || true
                        sync-secrets >/dev/null 2>&1 || true

                        if (( release )); then new-release "${rest[@]}" || exit 1; out ""
                        else push "${rest[@]}" || exit 1
                        fi

                    ) || { failures=$(( failures + 1 )); continue; }

                done

            fi

        fi

        out "\n---------------------------------"

    done

    out ""

    (( failures == 0 )) || { err "Failed: ${failures} failure(s)"; return; }
    (( dry )) && { info "Done"; return; }

    succ "Done"

}
fleet-sync () {

    fine "$@" || return
    fleet --sync "$@"

}
fleet-fine () {

    fine "$@" || return
    fleet --sync --push "$@"

}
fleet-ship () {

    ship "$@" || return
    fleet --sync --backup --push "$@"

}
fleet-release () {

    release "$@" || return
    fleet --sync --backup --push --release null "$@"

}
