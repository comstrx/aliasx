
release-list () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return

    gh release list --repo "${name}" "$@"

}
releases () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return

    gh release list --repo "${name}" --limit 100000 --json tagName --jq 'length' "$@"

}

release-exists () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(tag "${name}")" || return

    gh release view "${name}" "$@" >/dev/null 2>&1

}
find-release () {

    need gh || return

    local query="${1:-}" name=""
    shift >/dev/null 2>&1 || true

    [[ -n "${query}" ]] || { err "Missing release query"; return; }

    name="$(repo)" || return

    gh release list --repo "${name}" --limit 100000 --json tagName,name \
        --jq ".[] | select((.tagName // \"\" | contains(\"${query}\")) or (.name // \"\" | contains(\"${query}\"))) | \"https://github.com/${name}/releases/tag/\" + .tagName" "$@"

}

latest-release () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(repo "${name}")" || return

    gh release view --repo "${name}" --json url -q '.url' "$@" 2>/dev/null \
        || { err "No release found: ${name}"; return; }

}
release-url () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(tag "${name}")" || return

    gh release view "${name}" --json url -q '.url' "$@" 2>/dev/null \
        || { err "Release not found: ${name}"; return; }

}

new-release () {

    need git || return
    need gh  || return

    local tag="" name="" bin="" title="" notes="" root="" dir="" file="" hashname="" sums="" arg="" url="" force=0
    local -a rest=() args=() assets=() push_args=()

    while (( $# )); do

        arg="${1:-}"

        case "${arg}" in
            -m|--message)
                shift
                [[ -n "${1:-}" ]] || { err "Missing message value"; return; }
                push_args+=( --message "${1}" )
            ;;
            -t|--tag)
                shift
                [[ -n "${1:-}" ]] || { err "Missing tag value"; return; }
                tag="${1}"
            ;;
            -n|--name)
                shift
                [[ -n "${1:-}" ]] || { err "Missing name value"; return; }
                name="${1}"
            ;;
            -b|--bin)
                shift
                [[ -n "${1:-}" ]] || { err "Missing bin value"; return; }
                bin="${1}"
            ;;
            --title)
                shift
                [[ -n "${1:-}" ]] || { err "Missing title value"; return; }
                title="${1}"
            ;;
            --notes)
                shift
                [[ -n "${1:-}" ]] || { err "Missing notes value"; return; }
                notes="${1}"
            ;;
            --backup)
                push_args+=( --backup )
            ;;
            --sync)
                push_args+=( --sync )
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
                if   [[ -z "${tag}"   ]]; then tag="${arg}"
                elif [[ -z "${name}"  ]]; then name="${arg}"
                elif [[ -z "${bin}"   ]]; then bin="${arg}"
                elif [[ -z "${title}" ]]; then title="${arg}"
                elif [[ -z "${notes}" ]]; then notes="${arg}"
                else rest+=( "${arg}" )
                fi
            ;;
        esac

        shift >/dev/null 2>&1 || true

    done

    tag="$(tag "${tag}")"       || return
    name="$(name "${name}")"    || return
    root="$(rroot 2>/dev/null)" || return

    if (( force )); then push --tag "${tag}" --force "${push_args[@]}" || return
    else tag-exists "${tag}" || push --tag "${tag}" "${push_args[@]}" || return
    fi

    git ls-remote --exit-code --tags origin "refs/tags/${tag}" >/dev/null 2>&1 \
        || git push origin "refs/tags/${tag}" >/dev/null 2>&1 \
        || { err "Failed to push tag: ${tag}"; return; }

    [[ -n "${bin}" && ! -f "${bin}" && -f "${root}/${bin}" ]] && bin="${root}/${bin}"

    if [[ -n "${title}" ]]; then args+=( --title "${title}" )
    else args+=( --title "${name} ${tag}" )
    fi

    if [[ -f "${notes}" ]]; then args+=( --notes-file "${notes}" )
    elif [[ -n "${notes}" ]]; then args+=( --notes "${notes}" )
    elif [[ -f "${root}/CHANGELOG.md" ]]; then args+=( --notes-file "${root}/CHANGELOG.md" )
    elif ! tag-released "${tag}"; then args+=( --generate-notes )
    fi

    if [[ -f "${bin}" ]]; then

        need sha256sum || return

        dir="$(dirname -- "${bin}")"
        file="$(basename -- "${bin}")"
        hashname="SHA256SUMS"
        sums="${dir}/${hashname}"

        (
            cd -- "${dir}" || exit 1
            sha256sum -- "${file}" > "${hashname}" || exit 1
            sha256sum -c -- "${hashname}" >/dev/null 2>&1 || exit 1
        ) || { err "Failed to generate checksum"; return; }

        assets+=( "${bin}" "${sums}" )

    fi

    if tag-released "${tag}"; then

        gh release edit "${tag}" "${args[@]}" "${rest[@]}" >/dev/null 2>&1 \
            || { err "Failed to edit release: ${tag}"; return; }

        if (( ${#assets[@]} )); then

            gh release upload "${tag}" "${assets[@]}" --clobber >/dev/null 2>&1 \
                || { err "Failed to upload assets: ${tag}"; return; }

        fi

    else

        gh release create "${tag}" "${args[@]}" "${assets[@]}" --verify-tag "${rest[@]}" >/dev/null 2>&1 \
            || { err "Failed to release: ${tag}"; return; }

    fi

    url="$(gh release view "${tag}" --json url -q .url 2>/dev/null)" || true
    [[ -n "${url}" ]] || url="https://github.com/$(repo)/releases/tag/${tag}"

    succ "Released -> ${url}"

}
del-release () {

    need gh || return

    local name="${1:-}"
    shift >/dev/null 2>&1 || true

    name="$(tag "${name}")" || return

    gh release delete "${name}" --yes "$@" >/dev/null 2>&1 \
        || { err "Failed to delete release: ${name}"; return; }

    succ "Release deleted -> ${name}"

}
