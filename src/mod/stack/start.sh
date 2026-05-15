
start () {

    (
        local kind=""

        cdroot || return
        kind="$(lang)" || return

        case "${kind}" in
            php:laravel)

                [[ -d vendor ]] || build || return

                php artisan serve "$@"

            ;;
            php:php)

                local file=""
                file="$(entry php)" || { err "Missing PHP entry"; return; }

                php "${file}" "$@"

            ;;
            python:uv)

                if [[ -f manage.py ]]; then uv run python manage.py runserver "$@"
                elif [[ -f main.py    ]] && grep -qE '^[[:space:]]*app[[:space:]]*=[[:space:]]*FastAPI' main.py;        then uv run uvicorn main:app "$@"
                elif [[ -f app.py     ]] && grep -qE '^[[:space:]]*app[[:space:]]*=[[:space:]]*FastAPI' app.py;         then uv run uvicorn app:app "$@"
                elif [[ -f src/main.py ]] && grep -qE '^[[:space:]]*app[[:space:]]*=[[:space:]]*FastAPI' src/main.py;    then uv run uvicorn src.main:app "$@"
                elif [[ -f main.py    ]] && grep -qE '^[[:space:]]*app[[:space:]]*=[[:space:]]*Flask' main.py;          then uv run flask --app main run "$@"
                elif [[ -f app.py     ]] && grep -qE '^[[:space:]]*app[[:space:]]*=[[:space:]]*Flask' app.py;           then uv run flask --app app run "$@"
                else

                    local file=""
                    file="$(entry py)" || { err "Missing Python entry"; return; }

                    uv run python -O "${file}" "$@"

                fi

            ;;
            python:python)

                local py=""
                py="$(py-bin)" || return

                if [[ -f manage.py ]]; then "${py}" manage.py runserver "$@"
                elif [[ -f main.py    ]] && grep -qE '^[[:space:]]*app[[:space:]]*=[[:space:]]*FastAPI' main.py;        then "${py}" -m uvicorn main:app "$@"
                elif [[ -f app.py     ]] && grep -qE '^[[:space:]]*app[[:space:]]*=[[:space:]]*FastAPI' app.py;         then "${py}" -m uvicorn app:app "$@"
                elif [[ -f src/main.py ]] && grep -qE '^[[:space:]]*app[[:space:]]*=[[:space:]]*FastAPI' src/main.py;    then "${py}" -m uvicorn src.main:app "$@"
                elif [[ -f main.py    ]] && grep -qE '^[[:space:]]*app[[:space:]]*=[[:space:]]*Flask' main.py;          then "${py}" -m flask --app main run "$@"
                elif [[ -f app.py     ]] && grep -qE '^[[:space:]]*app[[:space:]]*=[[:space:]]*Flask' app.py;           then "${py}" -m flask --app app run "$@"
                else

                    local file=""
                    file="$(entry py)" || { err "Missing Python entry"; return; }

                    "${py}" -O "${file}" "$@"

                fi

            ;;
            rust:cargo)

                cargo run --release "$@"

            ;;
            go:go)

                local file="" bin=""

                mkdir -p build

                if [[ -f main.go ]]; then

                    go build -trimpath -ldflags="-s -w" -o build/app . || return
                    ./build/app "$@"

                elif [[ -d cmd ]]; then

                    file="$(find cmd -mindepth 2 -maxdepth 2 -type f -name main.go | head -n 1)"
                    [[ -n "${file}" ]] || { err "Missing Go entry"; return; }

                    bin="build/$(basename "$(dirname "${file}")")"

                    go build -trimpath -ldflags="-s -w" -o "${bin}" "./$(dirname "${file}")" || return
                    "${bin}" "$@"

                else
                    go run . "$@"
                fi

            ;;
            zig:zig)

                zig build -Doptimize=ReleaseFast run "$@"

            ;;
            cpp:xmake)

                xmake f -m release && xmake run "$@"

            ;;
            cmake:cmake)

                local file=""

                cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release || return

                file="$(cmake-bin)" || return
                "${file}" "$@"

            ;;
            dotnet:dotnet)

                dotnet run -c Release "$@"

            ;;
            java:maven)

                local m="mvn" main=""
                [[ -x ./mvnw ]] && m="./mvnw"

                if grep -q 'spring-boot' pom.xml 2>/dev/null; then "${m}" spring-boot:run "$@"; return; fi

                main="$(find src/main/java -type f -name "*.java" 2>/dev/null | sed 's#^src/main/java/##; s#/#.#g; s#\.java$##' | head -n 1)"

                if [[ -n "${main}" ]]; then "${m}" -q compile exec:java -Dexec.mainClass="${main}" "$@"
                else "${m}" package "$@"
                fi

            ;;
            java:gradle)

                local g="gradle"
                [[ -x ./gradlew ]] && g="./gradlew"

                if   grep -rq 'org.springframework.boot' build.gradle build.gradle.kts 2>/dev/null; then "${g}" bootRun "$@"
                elif "${g}" -q tasks --all 2>/dev/null | awk '{ print $1 }' | grep -Eq '(^|:)run$'; then "${g}" run "$@"
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

                dart run "$@"

            ;;
            dart:flutter)

                flutter run --release "$@"

            ;;
            bun:bun)

                build "$@" || return

                node-has start   && { node-script bun start   "$@"; return; }
                node-has preview && { node-script bun preview "$@"; return; }

                bun "$@" 2>/dev/null || node-entry "$@"

            ;;
            node:pnpm|node:yarn|node:npm)

                local node=""
                node="$(node-bin)" || return

                build "$@" || return

                node-has start   && { node-script "${node}" start   "$@"; return; }
                node-has preview && { node-script "${node}" preview "$@"; return; }

                node-entry "$@"

            ;;
            node:node)

                node-entry "$@"

            ;;
            sh:bash)

                local file=""
                file="$(entry sh)" || { err "Missing Bash entry"; return; }

                bash "${file}" "$@"

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
