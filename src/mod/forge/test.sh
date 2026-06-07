
tests () {

    (
        local kind=""

        cdroot || return
        kind="$(lang)" || return

        case "${kind}" in
            php:laravel)

                php artisan test "$@"

            ;;
            php:php)

                if [[ -x vendor/bin/pest ]]; then vendor/bin/pest "$@"
                elif [[ -x vendor/bin/phpunit ]]; then vendor/bin/phpunit "$@"
                else check "$@"
                fi

            ;;
            python:uv)

                if uv run pytest --version >/dev/null 2>&1; then uv run pytest "$@"
                elif [[ -d tests ]]; then uv run python -m unittest discover "$@"
                else check "$@"
                fi

            ;;
            python:python)

                local py=""
                py="$(python-bin)" || return

                if "${py}" -m pytest --version >/dev/null 2>&1; then "${py}" -m pytest "$@"
                elif [[ -d tests ]]; then "${py}" -m unittest discover "$@"
                else check "$@"
                fi

            ;;
            rust:cargo)

                cargo test "$@"

            ;;
            go:go)

                go test ./... "$@"

            ;;
            zig:zig)

                zig build test "$@"

            ;;
            cpp:xmake)

                xmake test "$@"

            ;;
            cmake:cmake)

                cmake -S . -B build && cmake --build build && ctest --test-dir build "$@"

            ;;
            dotnet:dotnet)

                dotnet test "$@"

            ;;
            java:maven)

                if [[ -x ./mvnw ]]; then ./mvnw test "$@"
                else mvn test "$@"
                fi

            ;;
            java:gradle)

                if [[ -x ./gradlew ]]; then ./gradlew test "$@"
                else gradle test "$@"
                fi

            ;;
            mojo:pixi)

                pixi run mojo --version >/dev/null

            ;;
            mojo:mojo)

                mojo --version >/dev/null

            ;;
            dart:dart)

                dart test "$@"

            ;;
            dart:flutter)

                flutter test "$@"

            ;;
            bun:bun|node:pnpm|node:yarn|node:npm)

                local node="" script=""
                node="$(node-bin)" || return

                if [[ "${node}" == "bun" ]]; then

                    if find . -type f \( -name "*.test.*" -o -name "*.spec.*" -o -name "*_test.*" -o -name "*_spec.*" \) \
                            -not -path "./node_modules/*" -not -path "./.git/*" -print -quit 2>/dev/null | grep -q .; then
                        bun test "$@"
                    else
                        check "$@"
                    fi

                    return

                fi
                if node-has test; then

                    if command -v jq >/dev/null 2>&1; then
                        script="$(jq -r '.scripts.test // empty' package.json 2>/dev/null)"
                    fi
                    if [[ "${script}" != 'echo "Error: no test specified" && exit 1' ]]; then
                        node-script "${node}" test "$@"
                        return
                    fi

                fi

                check "$@"

            ;;
            node:node)

                check "$@"

            ;;
            sh:bash)

                local file=""

                if   [[ -f test.sh ]]; then bash test.sh "$@"
                elif [[ -f tests.sh ]]; then bash tests.sh "$@"
                elif [[ -f src/test.sh ]]; then bash src/test.sh "$@"
                elif [[ -f src/tests.sh ]]; then bash src/tests.sh "$@"
                elif file="$(entry sh)"; then bash "${file}" test "$@"
                else check "$@"
                fi

            ;;
            lua:lua)

                if [[ -f test.lua ]]; then lua test.lua "$@"
                elif [[ -f src/test.lua ]]; then lua src/test.lua "$@"
                else check "$@"
                fi

            ;;
            *)

                err "Unsupported project type"

            ;;
        esac

    )

}
