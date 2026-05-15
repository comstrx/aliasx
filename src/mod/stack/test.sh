
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

                if   [[ -x vendor/bin/pest    ]]; then vendor/bin/pest "$@"
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
                py="$(py-bin)" || return

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
            bun:bun)

                node-has test && { node-script bun test "$@"; return; }

                bun test "$@"

            ;;
            node:pnpm|node:yarn|node:npm)

                local node=""
                node="$(node-bin)" || return

                node-has test && { node-script "${node}" test "$@"; return; }

                check "$@"

            ;;
            node:node)

                check "$@"

            ;;
            sh:bash)

                if   [[ -f test.sh     ]]; then bash test.sh     "$@"
                elif [[ -f src/test.sh ]]; then bash src/test.sh "$@"
                else check "$@"
                fi

            ;;
            lua:lua)

                if   [[ -f test.lua     ]]; then lua test.lua     "$@"
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
