
build () {

    (
        local kind=""

        cdroot || return
        kind="$(lang)" || return

        case "${kind}" in
            php:laravel)

                local node=""
                node="$(node-bin 2>/dev/null)"

                [[ -d vendor ]] || composer install || return
                composer dump-autoload -o || return

                if [[ -f package.json && -n "${node}" ]]; then

                    [[ -d node_modules ]] || "${node}" install || return
                    node-script "${node}" build "$@" || return

                fi

            ;;
            php:php)

                [[ -d vendor ]] || composer install || return
                composer dump-autoload -o "$@"

            ;;
            python:uv)

                if [[ -f pyproject.toml ]] && grep -qE '^\[build-system\]' pyproject.toml; then uv build "$@"
                else check "$@"
                fi

            ;;
            python:python)

                local py=""
                py="$(py-bin)" || return

                if [[ -f pyproject.toml || -f setup.py || -f setup.cfg ]]; then "${py}" -m build "$@"
                else check "$@"
                fi

            ;;
            rust:cargo)

                cargo build "$@"

            ;;
            go:go)

                local dir=""
                mkdir -p build

                if [[ -f main.go ]]; then

                    go build -o build/app . "$@"

                elif [[ -d cmd ]]; then

                    for dir in cmd/*; do
                        [[ -d "${dir}" && -f "${dir}/main.go" ]] || continue
                        go build -o "build/${dir##*/}" "./${dir}" "$@" || return
                    done

                else

                    go build ./... "$@"

                fi

            ;;
            zig:zig)

                zig build "$@"

            ;;
            cpp:xmake)

                xmake build "$@"

            ;;
            cmake:cmake)

                cmake -S . -B build "$@" && cmake --build build

            ;;
            dotnet:dotnet)

                dotnet build "$@"

            ;;
            java:maven)

                if [[ -x ./mvnw ]]; then ./mvnw package -DskipTests "$@"
                else mvn package -DskipTests "$@"
                fi

            ;;
            java:gradle)

                if [[ -x ./gradlew ]]; then ./gradlew build -x test "$@"
                else gradle build -x test "$@"
                fi

            ;;
            mojo:pixi)

                pixi run mojo --version >/dev/null

            ;;
            mojo:mojo)

                mojo --version >/dev/null

            ;;
            dart:dart)

                local file=""
                file="$(entry dart)" || { err "Missing Dart entry"; return; }

                mkdir -p build
                dart compile exe "${file}" -o build/app "$@"

            ;;
            dart:flutter)

                local target="${1:-apk}"
                shift 2>/dev/null

                flutter build "${target}" "$@"

            ;;
            bun:bun|node:pnpm|node:yarn|node:npm)

                node-script "$(node-bin)" build "$@"

            ;;
            node:node)

                node-check "$@"

            ;;
            sh:bash)

                local file=""

                if   [[ -f build.sh ]]; then bash build.sh "$@"
                elif [[ -f src/build.sh ]]; then bash src/build.sh "$@"
                elif file="$(entry sh)"; then bash "${file}" build "$@"
                else check "$@"
                fi

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
