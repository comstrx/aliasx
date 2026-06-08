
saasx () {

    local mono base dist source src_path dst_path seed conf ignore exc
    local dry=0 push=0 sync=0 backup=0 failures=0 seed_fail=0 conf_fail=0 msg="" tag="" sha="" arg=""

    local -a sources=() dists=() roots=() confs=() excludes=() flags=() rest=() args=() ignored=()

    dists=( visax zainx )
    sources=( infra engine server admin docs )

    roots=( LICENSE README.md )
    confs=( .gitignore .gitattributes .editorconfig .dockerignore )
    excludes=( "/.git" "/.env" "/.env.local" "/.env.production" "/.secret" "/.secrets" "/profiles/" )

    mono="$(rroot)" || return 0
    base="$(dirname "${mono}")" || return 0
    [[ "$(basename "${mono}")" == "saasx" ]] || return 0

    while (( $# )); do

        arg="${1:-}"

        case "${arg}" in
            -t|--tag)
                shift
                [[ -n "${1:-}" ]] || { err "Missing tag value"; return; }
                tag="${1}"
            ;;
            --dry|--dry-run)
                dry=1
            ;;
            --push)
                push=1
            ;;
            --sync)
                sync=1
            ;;
            --backup)
                backup=1
            ;;
            --)
                shift
                rest+=( "$@" )
                break
            ;;
            *)
                rest+=( "${arg}" )
            ;;
        esac

        shift >/dev/null 2>&1 || true

    done

    flags=( -a --delete --no-links )
    (( dry )) && flags+=( --dry-run --itemize-changes )

    tag="$(tag "${tag}")"
    [[ -n "${tag}" ]] && rest+=( --tag "${tag}" )

    sha="$(git -C "${mono}" rev-parse --short HEAD 2>/dev/null || true)"
    msg="${tag:+${tag}@}${sha:+${sha}@}commit"

    args=( "${rest[@]}" )
    [[ -n "${msg}" ]] && args+=( --message "${msg}" )

    for conf in "${confs[@]}"; do ignored+=( "--exclude=/${conf}" ); done
    for ignore in "${excludes[@]}"; do ignored+=( "--exclude=${ignore}" ); done
    while IFS= read -r ignore; do ignored+=( "--exclude=${ignore}" ); done < <(ignores)

    for dist in "${dists[@]}"; do

        out "\n------------- ${dist} -------------\n"

        for source in "${sources[@]}"; do

            src_path="${mono}/${source}/"
            dst_path="${base}/${dist}/${source}"

            (( dry )) && { out ""; info "Send: ${source}\n"; }

            if [[ ! -d "${src_path}" ]]; then

                err "Missing source: ${src_path}"
                failures=$(( failures + 1 ))
                continue

            fi
            if (( ! dry )) && ! mkdir -p "${dst_path}"; then

                err "Mkdir failed: ${dst_path}"
                failures=$(( failures + 1 ))
                continue

            fi
            if ! rsync "${flags[@]}" "${ignored[@]}" "${src_path}" "${dst_path}/"; then

                err "Rsync failed: ${dist}/${source}"
                failures=$(( failures + 1 ))
                continue

            fi

            conf_fail=0
            (( dry )) && continue

            for conf in "${confs[@]}"; do

                [[ -f "${mono}/${conf}" ]] || continue
                cp "${mono}/${conf}" "${dst_path}/${conf}" && continue

                err "Sync failed: ${dst_path}/${conf}"
                failures=$(( failures + 1 ))
                conf_fail=1

            done
            for exc in "${excludes[@]}"; do

                [[ "${exc}" == "/.git" ]] && continue
                [[ -e "${src_path}/${exc#/}" ]] || continue
                [[ -e "${dst_path}/${exc#/}" ]] && continue

                cp -a "${src_path}/${exc#/}" "${dst_path}/${exc#/}" && continue

                err "Seed failed: ${dst_path}/${exc#/}"
                failures=$(( failures + 1 ))
                conf_fail=1

            done

            (( conf_fail )) && continue

            (

                cd "${dst_path}" || exit 1
                isrepo || exit 0
                (( push )) || exit 0

                out ""
                sync-vars    >/dev/null 2>&1 || true
                sync-secrets >/dev/null 2>&1 || true

                push "${args[@]}" || exit 1

            ) || { failures=$(( failures + 1 )); continue; }

            succ "Sent: ${source}"

        done

        seed_fail=0
        (( dry )) && { out "\n---------------------------------"; continue; }

        if ! mkdir -p "${base}/${dist}"; then

            err "Mkdir failed: ${base}/${dist}"
            failures=$(( failures + 1 ))
            continue

        fi
        for seed in "${roots[@]}" "${confs[@]}"; do

            [[ -f "${mono}/${seed}" ]] || continue
            cp "${mono}/${seed}" "${base}/${dist}/${seed}" && continue

            err "Sync failed: ${base}/${dist}/${seed}"
            failures=$(( failures + 1 ))
            seed_fail=1

        done

        (( seed_fail )) && continue

        (

            cd "${base}/${dist}" || exit 1
            (( push || sync || backup )) || exit 0

            out ""
            sync-vars    >/dev/null 2>&1 || true
            sync-secrets >/dev/null 2>&1 || true

            (( push ))   && { push "${rest[@]}" || exit 1; }
            (( sync ))   && { syncdir || exit 1; }
            (( backup )) && { backup "" "" "${tag}" || exit 1; }

        ) || { failures=$(( failures + 1 )); continue; }

        out "\n---------------------------------"

    done

    out ""

    (( failures == 0 )) || { err "\n\n>> Failed: ${failures} failure(s)"; return; }
    (( dry )) && { info "Done: ${msg}"; return; }

    succ "Done: ${msg}"

}
fine () {

    sync-vars    >/dev/null 2>&1 || true
    sync-secrets >/dev/null 2>&1 || true

    push --sync "$@" || return
    saasx --sync --push "$@" || return

}
ship () {

    sync-vars    >/dev/null 2>&1 || true
    sync-secrets >/dev/null 2>&1 || true

    push --sync --backup "$@" || return
    saasx --sync --backup --push "$@" || return

}
gone () {

    local rc=0

    fine "$@" || { rc=$?; warn "push failed — locking anyway"; }
    lockscreen || rc=1

    return "${rc}"

}
