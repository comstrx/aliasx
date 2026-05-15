
run () {

    (
        local kind=""

        cdroot || return
        kind="$(lang)" || return

        case "${kind}" in
            php:laravel)

                local arg="" flags=1 node=""

                [[ -d vendor ]] || composer install || return

                node="$(node-bin 2>/dev/null)"
                [[ -f package.json && -n "${node}" && ! -d node_modules ]] && { "${node}" install || return; }

                for arg in "$@"; do
                    [[ "${arg}" == -- ]] && break
                    [[ "${arg}" == -* ]] || { flags=0; break; }
                done

                if (( $# == 0 || flags )); then php artisan serve "$@"
                else php artisan "$@"
                fi

            ;;
            php:php)

                local file=""
                file="$(entry php)" || { err "Missing PHP entry"; return; }

                [[ ! -f composer.json || -d vendor ]] || composer install || return
                php "${file}" "$@"

            ;;
            python:uv)

                local file=""
                file="$(entry py)" || { err "Missing Python entry"; return; }

                uv run python "${file}" "$@"

            ;;
            python:python)

                local file="" py=""

                file="$(entry py)" || { err "Missing Python entry"; return; }
                py="$(python-bin)"     || return

                "${py}" "${file}" "$@"

            ;;
            rust:cargo)

                cargo run "$@"

            ;;
            go:go)

                local file=""

                if [[ -f main.go ]]; then

                    go run . "$@"

                elif [[ -d cmd ]]; then

                    file="$(find cmd -mindepth 2 -maxdepth 2 -type f -name main.go | head -n 1)"
                    [[ -n "${file}" ]] || { err "Missing Go entry"; return; }

                    go run "./$(dirname "${file}")" "$@"

                else

                    go run . "$@"

                fi

            ;;
            zig:zig)

                zig build run "$@"

            ;;
            cpp:xmake)

                xmake run "$@"

            ;;
            cmake:cmake)

                local file=""

                cmake -S . -B build && cmake --build build || return

                file="$(cmake-bin)" || return
                "${file}" "$@"

            ;;
            dotnet:dotnet)

                dotnet run "$@"

            ;;
            java:maven)

                local m="mvn" main=""
                [[ -x ./mvnw ]] && m="./mvnw"

                main="$(find src/main/java -type f -name "*.java" 2>/dev/null | sed 's#^src/main/java/##; s#/#.#g; s#\.java$##' | head -n 1)"

                if [[ -n "${main}" ]]; then "${m}" -q compile exec:java -Dexec.mainClass="${main}" "$@"
                else "${m}" package "$@"
                fi

            ;;
            java:gradle)

                local g="gradle"
                [[ -x ./gradlew ]] && g="./gradlew"

                if "${g}" -q tasks --all 2>/dev/null | awk '{ print $1 }' | grep -Eq '(^|:)run$'; then "${g}" run "$@"
                else "${g}" build "$@"
                fi

            ;;
            mojo:pixi)

                local file=""
                file="$(entry mojo)" || { err "Missing Mojo entry"; return; }

                pixi run mojo "${file}" "$@"

            ;;
            mojo:mojo)

                local file=""
                file="$(entry mojo)" || { err "Missing Mojo entry"; return; }

                mojo "${file}" "$@"

            ;;
            dart:dart)

                [[ -d .dart_tool ]] || dart pub get || return
                dart run "$@"

            ;;
            dart:flutter)

                [[ -d .dart_tool ]] || flutter pub get || return

                flutter run "$@"

            ;;
            bun:bun)

                [[ -d node_modules ]] || bun install || return

                if [[ $# -gt 0 ]]; then

                    node-has "$1" && { node-script bun "$@"; return; }
                    bun "$@"

                else

                    node-has dev   && { node-script bun dev;   return; }
                    node-has start && { node-script bun start; return; }

                    node-entry

                fi

            ;;
            node:pnpm|node:yarn|node:npm)

                local node=""
                node="$(node-bin)" || return

                [[ -d node_modules ]] || "${node}" install || return

                if [[ $# -gt 0 ]]; then

                    node-has "$1" && { node-script "${node}" "$@"; return; }
                    err "Script not found: $1"

                else

                    node-has dev   && { node-script "${node}" dev;   return; }
                    node-has start && { node-script "${node}" start; return; }

                    node-entry

                fi

            ;;
            node:node)

                node-entry "$@"

            ;;
            sh:bash)

                local file=""

                if   [[ -f run.sh ]]; then bash run.sh "$@"
                elif [[ -f src/run.sh ]]; then bash src/run.sh "$@"
                elif file="$(entry sh)"; then bash "${file}" "$@"
                else check "$@"
                fi

            ;;
            lua:lua)

                local file=""
                file="$(entry lua)" || { err "Missing Lua entry"; return; }

                lua "${file}" "$@"

            ;;
            *)

                err "Unsupported project type"

            ;;
        esac

    )

}
