
refresh () {

    (
        local cache=""
        local -a args=()

        cdroot || return

        while IFS= read -r cache; do

            [[ -n "${cache}" ]] || continue

            case "${cache}" in
                */*)               args+=( -path "./${cache}" -o ) ;;
                *'*'*|*'?'*|*'['*) args+=( -name "${cache}" -o ) ;;
                *)                 args+=( -path "./${cache}" -o -path "./${cache}/*" -o ) ;;
            esac

        done < <(caches)

        [[ "${#args[@]}" -gt 0 ]] || return 0

        unset 'args[${#args[@]}-1]'
        find . -xdev -not -path "./.git" -not -path "./.git/*" \( "${args[@]}" \) -prune -exec rm -rf -- {} + 2>/dev/null

    )

}
