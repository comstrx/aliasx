
check () {

    (
        local kind=""

        cdroot || return
        kind="$(lang)" || return

        case "${kind}" in
            php:laravel)

                php artisan about >/dev/null && php artisan route:list >/dev/null

            ;;
            php:php)

                local file=""

                while IFS= read -r -d '' file; do
                    php -l "${file}" || return
                done < <(find . -type f -name "*.php" -not -path "./vendor/*" -print0)

            ;;
            python:uv)

                uv run python -m compileall -q . "$@"

            ;;
            python:python)

                local py=""
                py="$(py-bin)" || return

                "${py}" -m compileall -q . "$@"

            ;;
            rust:cargo)

                cargo check "$@"

            ;;
            go:go)

                go vet ./... "$@"

            ;;
            zig:zig)

                zig build "$@"

            ;;
            cpp:xmake)

                xmake check "$@" || xmake build "$@"

            ;;
            cmake:cmake)

                cmake -S . -B build "$@" && cmake --build build

            ;;
            dotnet:dotnet)

                dotnet build "$@"

            ;;
            java:maven)

                if [[ -x ./mvnw ]]; then ./mvnw compile "$@"
                else mvn compile "$@"
                fi

            ;;
            java:gradle)

                if [[ -x ./gradlew ]]; then ./gradlew classes "$@"
                else gradle classes "$@"
                fi

            ;;
            mojo:pixi)

                pixi run mojo --version >/dev/null

            ;;
            mojo:mojo)

                mojo --version >/dev/null

            ;;
            dart:dart)

                dart analyze "$@"

            ;;
            dart:flutter)

                flutter analyze "$@"

            ;;
            bun:bun|node:pnpm|node:yarn|node:npm)

                local node=""
                node="$(node-bin)" || return

                node-has lint && { node-script "${node}" lint "$@"; return; }
                node-check

            ;;
            node:node)

                node-check

            ;;
            sh:bash)

                local file=""

                while IFS= read -r -d '' file; do
                    shellcheck -s bash -x -e SC1090,SC1091,SC2016,SC2317,SC2119,SC2120 "${file}" "$@" || return
                done < <(find . -type f -name "*.sh" -not -path "./.git/*" -print0)

            ;;
            lua:lua)

                luac -p "$(entry lua)"

            ;;
            *)

                err "Unsupported project type"

            ;;
        esac

    )

}
