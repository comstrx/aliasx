
clean () {

    (
        local ignore=""
        local -a args=()

        cdroot || return

        while IFS= read -r ignore; do

            [[ -n "${ignore}" ]] || continue

            case "${ignore}" in
                */*)               args+=( -path "./${ignore}" -o ) ;;
                *'*'*|*'?'*|*'['*) args+=( -name "${ignore}" -o ) ;;
                *)                 args+=( -path "./${ignore}" -o -path "./${ignore}/*" -o ) ;;
            esac

        done < <(ignores)

        [[ "${#args[@]}" -gt 0 ]] || return 0

        unset 'args[${#args[@]}-1]'
        find . -xdev -not -path "./.git" -not -path "./.git/*" \( "${args[@]}" \) -prune -exec rm -rf -- {} + 2>/dev/null

    )

}
