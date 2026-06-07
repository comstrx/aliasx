
build-release () {

    (
        local kind=""

        cdroot || return
        kind="$(lang)" || return

        case "${kind}" in
            php:laravel)

                local node=""
                node="$(node-bin 2>/dev/null)"

                if [[ -f package.json && -n "${node}" ]]; then

                    [[ -d node_modules ]] || "${node}" install || return
                    node-script "${node}" build "$@" || return

                fi

                composer install --no-dev -o || return
                php artisan optimize || true

            ;;
            php:php)

                composer install --no-dev -o "$@"

            ;;
            python:uv)

                if [[ -f pyproject.toml ]] && grep -qE '^\[build-system\]' pyproject.toml; then uv build "$@"
                else check "$@"
                fi

            ;;
            python:python)

                local py=""
                py="$(python-bin)" || return

                if [[ -f pyproject.toml || -f setup.py || -f setup.cfg ]]; then "${py}" -m build "$@"
                else check "$@"
                fi

            ;;
            rust:cargo)

                cargo build --release "$@"

            ;;
            go:go)

                local dir=""
                mkdir -p build

                if [[ -f main.go ]]; then

                    go build -trimpath -ldflags="-s -w" -o build/app . "$@"

                elif [[ -d cmd ]]; then

                    for dir in cmd/*; do
                        [[ -d "${dir}" && -f "${dir}/main.go" ]] || continue
                        go build -trimpath -ldflags="-s -w" -o "build/${dir##*/}" "./${dir}" "$@" || return
                    done

                else

                    go build -trimpath -ldflags="-s -w" ./... "$@"

                fi

            ;;
            zig:zig)

                zig build -Doptimize=ReleaseFast "$@"

            ;;
            cpp:xmake)

                xmake f -m release && xmake build "$@"

            ;;
            cmake:cmake)

                cmake -S . -B build -DCMAKE_BUILD_TYPE=Release "$@" && cmake --build build --config Release

            ;;
            dotnet:dotnet)

                dotnet publish -c Release "$@"

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
                shift 2>/dev/null || true
                flutter build "${target}" --release "$@"

            ;;
            bun:bun|node:pnpm|node:yarn|node:npm)

                local node=""
                node="$(node-bin)" || return

                [[ -d node_modules ]] || "${node}" install || return

                node-has build && { node-script "${node}" build "$@"; return; }
                return 0

            ;;
            node:node)

                node-check "$@"

            ;;
            sh:bash)

                local file=""

                if   [[ -f release.sh ]]; then bash release.sh "$@"
                elif [[ -f src/release.sh ]]; then bash src/release.sh "$@"
                elif file="$(entry sh)"; then bash "${file}" build-release "$@"
                else build "$@"
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
