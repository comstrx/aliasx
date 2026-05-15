
root () {

    local dir="" marker=""

    local -a files=(
        artisan
        composer.json
        Cargo.toml
        go.mod
        xmake.lua
        CMakeLists.txt
        build.zig
        pixi.toml
        mojo.toml
        pyproject.toml
        requirements.txt
        setup.py
        setup.cfg
        package.json
        bun.lock
        bun.lockb
        bunfig.toml
        pnpm-lock.yaml
        yarn.lock
        global.json
        pom.xml
        build.gradle
        build.gradle.kts
        mvnw
        gradlew
        src/main.rs
        src/main.go
        src/main.cpp
        src/main.c
        src/main.zig
        src/main.mojo
        src/main.py
        src/main.js
        src/main.ts
        src/main.php
        src/main.sh
        src/main.lua
        main.rs
        main.go
        main.cpp
        main.c
        main.zig
        main.mojo
        main.py
        main.js
        main.ts
        main.php
        main.sh
        main.lua
        index.js
        index.ts
        index.php
        index.sh
        index.lua
        run.py
        run.js
        run.ts
        run.php
        run.sh
        run.lua
    )
    local -a globs=(
        "*.sln"
        "*.csproj"
        "*.fsproj"
        "*.vbproj"
    )

    dir="$(git rev-parse --show-toplevel 2>/dev/null)" && { out "${dir}"; return; }
    dir="$(pwd -P)"

    while true; do

        for marker in "${files[@]}"; do
            [[ -f "${dir}/${marker}" ]] && { out "${dir}"; return; }
        done
        for marker in "${globs[@]}"; do
            compgen -G "${dir}/${marker}" >/dev/null && { out "${dir}"; return; }
        done

        [[ "${dir}" == "/" ]] && break
        dir="$(dirname -- "${dir}")"

    done

    out "$(pwd -P)"

}
cdroot () {

    cd "$(root)" || { err "cannot cd project root"; return; }

}
ignores () {

    cat <<-EOF
	.cache
	.DS_Store
	.eggs
	.hg
	.idea
	.lua
	.mypy_cache
	.next
	.nox
	.npm
	.nuxt
	.expo
	.parcel-cache
	.pnpm-store
	.pytest_cache
	.ruff_cache
	.svelte-kit
	.svn
	.tox
	.turbo
	.venv
	.vercel
	.vite
	.vs
	.vscode
	.xmake
	.xmake_cache
	.yarn
	.gradle
	.zig-cache
	.pixi
	.mvn
	.mojopkg
	.mojo
	.coverage
	.node_modules
	.pyre
	*.log
	*.o
	*.so
	*.obj
	*.out
	*.exe
	*.egg-info
	__pycache__
	bower_components
	cmake-build-*
	CMakeCache.txt
	CMakeFiles
	compile_commands.json
	coverage
	luarocks
	lua_modules
	node_modules
	htmlcov
	Thumbs.db
	xmake-build
	xmake-cache
	public/build
	public/storage
	storage/framework/cache/data/*
	storage/framework/sessions/*
	storage/framework/views/*
	bootstrap/cache/*.php
	storage/logs/*.log
	.phpunit.result.cache
	zig-out
	zig-cache
	build
	dist
	bin
	obj
	target
	vendor
	venv
	EOF

}

lang () {

    (
        cdroot || return

        if [[ -f artisan ]]; then out php:laravel
        elif [[ -f composer.json ]]; then out php:php

        elif [[ -f Cargo.toml ]]; then out rust:cargo
        elif [[ -f go.mod ]]; then out go:go
        elif [[ -f build.zig ]]; then out zig:zig

        elif [[ -f pixi.toml ]] && { compgen -G "*.mojo" >/dev/null || compgen -G "src/*.mojo" >/dev/null; }; then out mojo:pixi
        elif [[ -f mojo.toml ]]; then out mojo:mojo
        elif compgen -G "*.mojo" >/dev/null || compgen -G "src/*.mojo" >/dev/null; then out mojo:mojo

        elif [[ -f xmake.lua ]]; then out cpp:xmake
        elif [[ -f CMakeLists.txt ]]; then out cmake:cmake

        elif [[ -f pyproject.toml ]]; then out python:uv
        elif [[ -f requirements.txt ]]; then out python:python

        elif compgen -G "*.sln" >/dev/null; then out dotnet:dotnet
        elif compgen -G "*.csproj" >/dev/null; then out dotnet:dotnet
        elif compgen -G "*.fsproj" >/dev/null; then out dotnet:dotnet
        elif compgen -G "*.vbproj" >/dev/null; then out dotnet:dotnet
        elif [[ -f global.json ]]; then out dotnet:dotnet

        elif [[ -f mvnw || -f pom.xml ]]; then out java:maven
        elif [[ -f gradlew || -f build.gradle || -f build.gradle.kts ]]; then out java:gradle

        elif [[ -f bunfig.toml || -f bun.lock || -f bun.lockb ]]; then out bun:bun
        elif [[ -f pnpm-lock.yaml ]] || grep -qE '"packageManager"[[:space:]]*:[[:space:]]*"pnpm@' package.json 2>/dev/null; then out node:pnpm
        elif [[ -f yarn.lock ]] || grep -qE '"packageManager"[[:space:]]*:[[:space:]]*"yarn@' package.json 2>/dev/null; then out node:yarn
        elif [[ -f package.json ]]; then out node:npm

        elif [[ -f main.php || -f index.php || -f run.php || -f src/main.php || -f public/index.php || -f public/run.php ]]; then out php:php
        elif [[ -f main.py || -f index.py || -f run.py || -f src/main.py || -f src/index.py || -f src/run.py ]]; then out python:python
        elif [[ -f main.js || -f index.js || -f run.js || -f src/main.js || -f src/index.js || -f src/run.js ]]; then out node:node
        elif [[ -f main.ts || -f index.ts || -f run.ts || -f src/main.ts || -f src/index.ts || -f src/run.ts ]]; then out node:node
        elif [[ -f main.lua || -f index.lua || -f run.lua || -f src/main.lua || -f src/index.lua || -f src/run.lua ]]; then out lua:lua
        elif [[ -f main.sh || -f index.sh || -f run.sh || -f src/main.sh || -f src/index.sh || -f src/run.sh ]]; then out sh:bash

        fi

    )

}
entry () {

    (
        local ext="${1:-}" dir="" file="" ignore="" suffix=""
        local -a entries=() files=() args=()

        dir="$(root)" || return
        cd "${dir}"   || return

        if [[ -n "${ext}" ]]; then

            suffix="${ext#.}"

            entries=(
                "main.${suffix}" "index.${suffix}" "run.${suffix}" "src/main.${suffix}" "src/index.${suffix}"
                "src/run.${suffix}" "public/index.${suffix}" "public/run.${suffix}"
            )

        else

            entries=(
                main.* index.* run.* src/main.* src/index.*
                src/run.* public/index.* public/run.*
            )

        fi

        for file in "${entries[@]}"; do
            [[ -f "${file}" ]] && { out "${dir}/${file}"; return; }
        done

        while IFS= read -r ignore; do

            [[ -n "${ignore}" ]] || continue

            case "${ignore}" in
                */*) args+=( -not -path "./${ignore}" ) ;;
                *'*'*|*'?'*|*'['*) args+=( -not -name "${ignore}" ) ;;
                *) args+=( -not -path "./${ignore}" -not -path "./${ignore}/*" ) ;;
            esac

        done < <(ignores)

        if [[ -n "${ext}" ]]; then suffix="*.${ext#.}"
        else suffix="*"
        fi

        while IFS= read -r -d '' file; do
            files+=( "${file#./}" )
        done < <(find . -type f -name "${suffix}" "${args[@]}" -print0 2>/dev/null)

        [[ "${#files[@]}" -eq 1 ]] || return
        out "${dir}/${files[0]}"

    )

}

cmake-bin () {

    local file="" dir=""

    for dir in build/bin build; do

        [[ -d "${dir}" ]] || continue

        file="$(
            find "${dir}" -maxdepth 2 -type f -perm -111 \
                -not -path "*/CMakeFiles/*" \
                -not -name "*.so" \
                -not -name "*.so.*" \
                -not -name "*.dll" \
                -not -name "*.dylib" \
                -not -name "*.a" \
                -not -name "test_*" \
                -not -name "*_test" \
                -not -name "*Test*" \
                -not -name "*Tests*" \
                | sort \
                | head -n 1
        )"

        [[ -n "${file}" ]] && { out "${file}"; return; }

    done

    err "Missing CMake executable"

}
node-check-entry () {

    local file=""

    if file="$(entry js 2>/dev/null)"; then

        ensure node || return
        node --check "${file}"
        return

    fi
    if file="$(entry ts 2>/dev/null)"; then

        ensure tsc || return

        if [[ -f tsconfig.json ]]; then tsc --noEmit
        else tsc --noEmit "${file}"
        fi

        return

    fi

    err "Missing Node entry"

}
node-entry-run () {

    local rc=$?
    local file="" kind=""

    (( rc >= 128 )) && return "${rc}"
    kind="$(lang)" || return

    if file="$(entry ts 2>/dev/null)"; then

        case "${kind}" in
            bun:bun)
                ensure bun || return
                bun "${file}" "$@"
            ;;
            *)
                if command -v tsx >/dev/null 2>&1; then tsx "${file}" "$@"
                elif command -v bun >/dev/null 2>&1; then bun "${file}" "$@"
                else err "Missing tsx or bun for TypeScript entry"; return
                fi
            ;;
        esac

    elif file="$(entry js 2>/dev/null)"; then

        case "${kind}" in
            bun:bun)
                ensure bun || return
                bun "${file}" "$@"
            ;;
            *)
                ensure node || return
                node "${file}" "$@"
            ;;
        esac

    else

        err "Missing Node entry"
        return

    fi

}
node-script-run () {

    (
        local tool="${1:-}" name="${2:-}" fallback="${3:-}" runner="node" has_script=""

        [[ -n "${tool}" ]] || return
        [[ -n "${name}" ]] || return

        ensure "${tool}" || return
        cdroot || return

        [[ -f package.json ]] || return
        [[ "${tool}" == "bun" ]] && runner="bun"

        has_script="process.exit(require('./package.json').scripts?.['${name}'] ? 0 : 1)"

        if command -v "${runner}" >/dev/null 2>&1 && "${runner}" -e "${has_script}" 2>/dev/null; then

            [[ -d node_modules ]] || "${tool}" install || return

            case "${tool}" in
                bun)  bun  run "${name}" "${@:4}" ;;
                pnpm) pnpm run "${name}" "${@:4}" ;;
                yarn) yarn     "${name}" "${@:4}" ;;
                npm)  npm  run "${name}" "${@:4}" ;;
                *)    return 1 ;;
            esac

        elif [[ -n "${fallback}" ]]; then

            case "${tool}" in
                bun)  bun  "${fallback}" "${@:4}" ;;
                pnpm) pnpm "${fallback}" "${@:4}" ;;
                yarn) yarn "${fallback}" "${@:4}" ;;
                npm)  npm  "${fallback}" "${@:4}" ;;
                *)    return 1 ;;
            esac

        else

            return 1

        fi

    )

}

clean () {

    (
        local ignore=""
        local -a args=()

        cdroot || return

        while IFS= read -r ignore; do

            [[ -n "${ignore}" ]] || continue

            case "${ignore}" in
                */*) args+=( -path "./${ignore}" -o ) ;;
                *'*'*|*'?'*|*'['*) args+=( -name "${ignore}" -o ) ;;
                *) args+=( -path "./${ignore}" -o -path "./${ignore}/*" -o ) ;;
            esac

        done < <(ignores)

        [[ "${#args[@]}" -gt 0 ]] || return 0

        unset 'args[${#args[@]}-1]'

        find . \( "${args[@]}" \) -prune -exec rm -rf -- {} + 2>/dev/null
        find . -type f -name "*:Zone.Identifier" -delete 2>/dev/null

    ) || return

    succ "Cleaned"

}
refresh () {

    (
        cdroot || return

        case "$(lang)" in
            php:laravel)
                php artisan optimize:clear "$@" && composer dump-autoload
            ;;
            php:php)
                composer dump-autoload
            ;;
            python:python)
                find . -type d -name "__pycache__" -prune -exec rm -rf {} + 2>/dev/null
                find . -type f -name "*.pyc" -delete 2>/dev/null
                rm -rf .mypy_cache .pytest_cache .ruff_cache
            ;;
            python:uv)
                find . -type d -name "__pycache__" -prune -exec rm -rf {} + 2>/dev/null
                find . -type f -name "*.pyc" -delete 2>/dev/null
                rm -rf .mypy_cache .pytest_cache .ruff_cache
                uv cache prune "$@" 2>/dev/null || true
            ;;
            go:go)
                go clean -cache -testcache "$@"
            ;;
            cmake:cmake)
                rm -rf CMakeCache.txt CMakeFiles compile_commands.json
            ;;
            zig:zig)
                rm -rf .zig-cache zig-cache
            ;;
            mojo:pixi)
                pixi clean "$@" 2>/dev/null || true
            ;;
            bun:bun|node:pnpm|node:yarn|node:npm|node:node)
                rm -rf .next/cache .nuxt .vite .svelte-kit .turbo .parcel-cache node_modules/.cache .eslintcache coverage
            ;;
            sh:bash) : ;;
            lua:lua) : ;;
            rust:cargo) : ;;
            cpp:xmake) : ;;
            mojo:mojo) : ;;
            dotnet:dotnet) : ;;
            java:maven) : ;;
            java:gradle) : ;;
            *)
                err "Unsupported project type"
            ;;
        esac

    ) || return

    succ "Refreshed"

}

check () {

    (
        cdroot || return

        case "$(lang)" in
            lua:lua)
                luac -p "$(entry lua)"
            ;;
            sh:bash)
                find . -type f -name "*.sh" -not -path "./.git/*" -print0 |
                    xargs -0 shellcheck -s bash -x -e SC1090,SC1091,SC2016,SC2317,SC2119,SC2120
            ;;
            php:php)
                find . -type f -name "*.php" -not -path "./vendor/*" -print0 |
                    xargs -0 -n1 php -l
            ;;
            php:laravel)
                php artisan about >/dev/null && php artisan route:list >/dev/null
            ;;
            python:python)
                [[ -n "${VIRTUAL_ENV:-}" || -x .venv/bin/python ]] || python3 -m venv .venv || return

                if [[ -x .venv/bin/python && -z "${VIRTUAL_ENV:-}" ]]; then .venv/bin/python -m compileall -q .
                else python -m compileall -q .
                fi
            ;;
            python:uv)
                uv run python -m compileall -q .
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
            mojo:pixi)
                pixi run mojo --version >/dev/null
            ;;
            mojo:mojo)
                mojo --version >/dev/null
            ;;
            cpp:xmake)
                xmake check "$@" || xmake build "$@"
            ;;
            cmake:cmake)
                cmake -S . -B build && cmake --build build "$@"
            ;;
            bun:bun)
                node-script-run bun lint "" "$@" || node-script-run bun build "" "$@" || {
                    file="$(entry ts 2>/dev/null || entry js 2>/dev/null)" || return
                    bun build "${file}" --target=bun --outdir /tmp/aliasx-bun-check >/dev/null
                    rm -rf /tmp/aliasx-bun-check
                }
            ;;
            node:pnpm)
                node-script-run pnpm lint "" "$@" || node-script-run pnpm build "" "$@" || node-check-entry
            ;;
            node:yarn)
                node-script-run yarn lint "" "$@" || node-script-run yarn build "" "$@" || node-check-entry
            ;;
            node:npm)
                node-script-run npm lint "" "$@" || node-script-run npm build "" "$@" || node-check-entry
            ;;
            node:node)
                node-check-entry
            ;;
            dotnet:dotnet)
                dotnet build "$@"
            ;;
            java:maven)
                if [[ -x ./mvnw ]]; then ./mvnw compile "$@"; else mvn compile "$@"; fi
            ;;
            java:gradle)
                if [[ -x ./gradlew ]]; then ./gradlew classes "$@"; else gradle classes "$@"; fi
            ;;
            *)
                err "Unsupported project type"
            ;;
        esac

    )

}
tests () {

    (
        cdroot || return

        case "$(lang)" in
            lua:lua)
                if [[ -f test.lua ]]; then lua test.lua "$@"
                elif [[ -f src/test.lua ]]; then lua src/test.lua "$@"
                else check "$@"
                fi
            ;;
            sh:bash)
                if [[ -f test.sh ]]; then bash test.sh "$@"
                elif [[ -f src/test.sh ]]; then bash src/test.sh "$@"
                else check "$@"
                fi
            ;;
            php:php)
                if [[ -x vendor/bin/pest ]]; then vendor/bin/pest "$@"
                elif [[ -x vendor/bin/phpunit ]]; then vendor/bin/phpunit "$@"
                elif [[ -f test.php ]]; then php test.php "$@"
                elif [[ -f tests.php ]]; then php tests.php "$@"
                else check "$@"
                fi
            ;;
            php:laravel)
                php artisan test "$@"
            ;;
            python:python)
                [[ -n "${VIRTUAL_ENV:-}" || -x .venv/bin/python ]] || python3 -m venv .venv || return

                local py="python"
                [[ -x .venv/bin/python && -z "${VIRTUAL_ENV:-}" ]] && py=".venv/bin/python"

                if "${py}" -m pytest --version >/dev/null 2>&1; then "${py}" -m pytest "$@"
                elif [[ -f test.py ]]; then "${py}" test.py "$@"
                elif [[ -f tests.py ]]; then "${py}" tests.py "$@"
                elif compgen -G "test_*.py" >/dev/null; then for file in test_*.py; do "${py}" "${file}" "$@" || return; done
                elif [[ -d tests ]]; then "${py}" -m unittest discover "$@"
                else check "$@"
                fi
            ;;
            python:uv)
                if uv run pytest --version >/dev/null 2>&1; then uv run pytest "$@"
                elif [[ -f test.py ]]; then uv run python test.py "$@"
                elif [[ -f tests.py ]]; then uv run python tests.py "$@"
                elif compgen -G "test_*.py" >/dev/null; then for file in test_*.py; do uv run python "${file}" "$@" || return; done
                elif [[ -d tests ]]; then uv run python -m unittest discover "$@"
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
            mojo:pixi)
                pixi run mojo --version >/dev/null
            ;;
            mojo:mojo)
                mojo --version >/dev/null
            ;;
            cpp:xmake)
                xmake test "$@"
            ;;
            cmake:cmake)
                cmake -S . -B build && cmake --build build && ctest --test-dir build "$@"
            ;;
            bun:bun)
                node-script-run bun test test "$@"
            ;;
            node:pnpm)
                node-script-run pnpm test test "$@"
            ;;
            node:yarn)
                node-script-run yarn test test "$@"
            ;;
            node:npm)
                node-script-run npm test test "$@"
            ;;
            node:node)
                check "$@"
            ;;
            dotnet:dotnet)
                dotnet test "$@"
            ;;
            java:maven)
                if [[ -x ./mvnw ]]; then ./mvnw test "$@"; else mvn test "$@"; fi
            ;;
            java:gradle)
                if [[ -x ./gradlew ]]; then ./gradlew test "$@"; else gradle test "$@"; fi
            ;;
            *)
                err "Unsupported project type"
            ;;
        esac

    )

}

build () {

    (
        cdroot || return

        case "$(lang)" in
            lua:lua)
                luac -p "$(entry lua)"
            ;;
            sh:bash)
                check "$@"
            ;;
            php:php)
                composer dump-autoload -o "$@"
            ;;
            php:laravel)
                mkdir -p bootstrap/cache storage/framework/cache storage/framework/sessions storage/framework/views storage/logs
                [[ -d vendor ]] || composer install || return

                composer dump-autoload -o "$@" && {
                    [[ ! -f package.json ]] ||
                    [[ -d node_modules ]] ||
                    { [[ -f bun.lock || -f bun.lockb || -f bunfig.toml ]] && bun install; } ||
                    { [[ -f pnpm-lock.yaml ]] && pnpm install; } ||
                    { [[ -f yarn.lock ]] && yarn install; } ||
                    { [[ -f package-lock.json ]] && npm ci; } ||
                    npm install
                } && {
                    [[ ! -f package.json ]] ||
                    { [[ -f bun.lock || -f bun.lockb || -f bunfig.toml ]] && node-script-run bun build "" "$@"; } ||
                    { [[ -f pnpm-lock.yaml ]] && node-script-run pnpm build "" "$@"; } ||
                    { [[ -f yarn.lock ]] && node-script-run yarn build "" "$@"; } ||
                    node-script-run npm build "" "$@"
                }
            ;;
            python:python)
                if [[ -f pyproject.toml || -f setup.py || -f setup.cfg ]]; then
                    [[ -n "${VIRTUAL_ENV:-}" || -x .venv/bin/python ]] || python3 -m venv .venv || return
                    if [[ -x .venv/bin/python && -z "${VIRTUAL_ENV:-}" ]]; then .venv/bin/python -m build "$@"
                    else python -m build "$@"
                    fi
                else
                    check "$@"
                fi
            ;;
            python:uv)
                if [[ -f pyproject.toml ]] && grep -qE '^\[build-system\]' pyproject.toml; then uv build "$@"
                else check "$@"
                fi
            ;;
            rust:cargo)
                cargo build "$@"
            ;;
            go:go)
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
            mojo:pixi)
                pixi run mojo --version >/dev/null
            ;;
            mojo:mojo)
                mojo --version >/dev/null
            ;;
            cpp:xmake)
                xmake build "$@"
            ;;
            cmake:cmake)
                cmake -S . -B build && cmake --build build "$@"
            ;;
            bun:bun)
                node-script-run bun build install "$@"
            ;;
            node:pnpm)
                node-script-run pnpm build install "$@"
            ;;
            node:yarn)
                node-script-run yarn build install "$@"
            ;;
            node:npm)
                node-script-run npm build install "$@"
            ;;
            node:node)
                check "$@"
            ;;
            dotnet:dotnet)
                dotnet build "$@"
            ;;
            java:maven)
                if [[ -x ./mvnw ]]; then ./mvnw package -DskipTests "$@"; else mvn package -DskipTests "$@"; fi
            ;;
            java:gradle)
                if [[ -x ./gradlew ]]; then ./gradlew build -x test "$@"; else gradle build -x test "$@"; fi
            ;;
            *)
                err "Unsupported project type"
            ;;
        esac

    )

}
build-release () {

    (
        cdroot || return

        case "$(lang)" in
            lua:lua)
                luac -p "$(entry lua)"
            ;;
            sh:bash)
                check "$@"
            ;;
            php:php)
                composer install --no-dev -o "$@"
            ;;
            php:laravel)
                mkdir -p bootstrap/cache storage/framework/cache storage/framework/sessions storage/framework/views storage/logs
                {
                    [[ ! -f package.json ]] ||
                    [[ -d node_modules ]] ||
                    { [[ -f bun.lock || -f bun.lockb || -f bunfig.toml ]] && bun install; } ||
                    { [[ -f pnpm-lock.yaml ]] && pnpm install; } ||
                    { [[ -f yarn.lock ]] && yarn install; } ||
                    { [[ -f package-lock.json ]] && npm ci; } ||
                    npm install
                } && {
                    [[ ! -f package.json ]] ||
                    { [[ -f bun.lock || -f bun.lockb || -f bunfig.toml ]] && node-script-run bun build "" "$@"; } ||
                    { [[ -f pnpm-lock.yaml ]] && node-script-run pnpm build "" "$@"; } ||
                    { [[ -f yarn.lock ]] && node-script-run yarn build "" "$@"; } ||
                    node-script-run npm build "" "$@"
                } && rm -rf -- vendor && composer install --no-dev -o "$@" && php artisan optimize
            ;;
            python:python)
                if [[ -f pyproject.toml || -f setup.py || -f setup.cfg ]]; then
                    [[ -n "${VIRTUAL_ENV:-}" || -x .venv/bin/python ]] || python3 -m venv .venv || return
                    if [[ -x .venv/bin/python && -z "${VIRTUAL_ENV:-}" ]]; then .venv/bin/python -m build "$@"
                    else python -m build "$@"
                    fi
                else
                    check "$@"
                fi
            ;;
            python:uv)
                if [[ -f pyproject.toml ]] && grep -qE '^\[build-system\]' pyproject.toml; then uv build "$@"
                else check "$@"
                fi
            ;;
            rust:cargo)
                cargo build --release "$@"
            ;;
            go:go)
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
            mojo:pixi)
                pixi run mojo --version >/dev/null
            ;;
            mojo:mojo)
                mojo --version >/dev/null
            ;;
            cpp:xmake)
                xmake f -m release && xmake build "$@"
            ;;
            cmake:cmake)
                cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build "$@"
            ;;
            bun:bun)
                node-script-run bun build install "$@"
            ;;
            node:pnpm)
                node-script-run pnpm build install "$@"
            ;;
            node:yarn)
                node-script-run yarn build install "$@"
            ;;
            node:npm)
                node-script-run npm build install "$@"
            ;;
            node:node)
                check "$@"
            ;;
            dotnet:dotnet)
                dotnet publish -c Release "$@"
            ;;
            java:maven)
                if [[ -x ./mvnw ]]; then ./mvnw package -DskipTests "$@"; else mvn package -DskipTests "$@"; fi
            ;;
            java:gradle)
                if [[ -x ./gradlew ]]; then ./gradlew build -x test "$@"; else gradle build -x test "$@"; fi
            ;;
            *)
                err "Unsupported project type"
            ;;
        esac

    )

}

add () {

    (
        local name="${1:-}"
        [[ -n "${name}" ]] || { err "Missing package name"; return; }

        cdroot || return

        case "$(lang)" in
            lua:lua)
                luarocks install "$@"
            ;;
            sh:bash)
                err "Unsupported dependency add for Bash project"
            ;;
            php:php)
                composer require "$@"
            ;;
            php:laravel)
                composer require "$@"
            ;;
            python:python)
                [[ -n "${VIRTUAL_ENV:-}" || -x .venv/bin/python ]] || python3 -m venv .venv || return

                if [[ -x .venv/bin/python && -z "${VIRTUAL_ENV:-}" ]]; then .venv/bin/python -m pip install "$@"
                else python -m pip install "$@"
                fi
            ;;
            python:uv)
                uv add "$@"
            ;;
            rust:cargo)
                cargo add "$@"
            ;;
            go:go)
                go get "$@"
            ;;
            zig:zig)
                zig fetch --save "$@"
            ;;
            mojo:pixi)
                pixi add "$@"
            ;;
            mojo:mojo)
                err "Unsupported dependency add for Mojo project without Pixi"
            ;;
            cpp:xmake)
                [[ -f xmake.lua ]] || { err "Missing xmake.lua"; return; }

                for pkg in "$@"; do
                    grep -qE "^[[:space:]]*add_requires\\([\"']${pkg}[\"']\\)" xmake.lua 2>/dev/null || {
                        awk -v pkg="${pkg}" '
                            BEGIN { added = 0 }
                            {
                                if ( !added && $0 ~ /^target\(/ ) {
                                    print "add_requires(\"" pkg "\")"
                                    print ""
                                    added = 1
                                }
                                print
                            }
                        ' xmake.lua > xmake.lua.tmp && mv xmake.lua.tmp xmake.lua
                    }
                    grep -qE "^[[:space:]]*add_packages\\([\"']${pkg}[\"']\\)" xmake.lua 2>/dev/null || {
                        awk -v pkg="${pkg}" '
                            BEGIN { added = 0 }
                            {
                                print
                                if ( !added && $0 ~ /^target\(/ ) {
                                    print "    add_packages(\"" pkg "\")"
                                    added = 1
                                }
                            }
                        ' xmake.lua > xmake.lua.tmp && mv xmake.lua.tmp xmake.lua
                    }
                    xmake require -y "${pkg}" || return
                done
            ;;
            cmake:cmake)
                err "Unsupported dependency add for CMake project"
            ;;
            bun:bun)
                bun add "$@"
            ;;
            node:pnpm)
                pnpm add "$@"
            ;;
            node:yarn)
                yarn add "$@"
            ;;
            node:npm)
                npm install "$@"
            ;;
            node:node)
                npm install "$@"
            ;;
            dotnet:dotnet)
                for pkg in "$@"; do dotnet add package "${pkg}" || return; done
            ;;
            java:maven)
                err "Maven dependencies must be added to pom.xml"
            ;;
            java:gradle)
                err "Gradle dependencies must be added to build.gradle"
            ;;
            *)
                err "Unsupported project type"
            ;;
        esac

    )

}
del () {

    (
        local name="${1:-}" pkg=""
        [[ -n "${name}" ]] || { err "Missing package name"; return; }

        cdroot || return

        case "$(lang)" in
            lua:lua)
                luarocks remove "$@"
            ;;
            sh:bash)
                err "Unsupported dependency remove for Bash project"
            ;;
            php:php)
                composer remove "$@"
            ;;
            php:laravel)
                composer remove "$@"
            ;;
            python:python)
                [[ -n "${VIRTUAL_ENV:-}" || -x .venv/bin/python ]] || python3 -m venv .venv || return

                if [[ -x .venv/bin/python && -z "${VIRTUAL_ENV:-}" ]]; then .venv/bin/python -m pip uninstall -y "$@"
                else python -m pip uninstall -y "$@"
                fi
            ;;
            python:uv)
                uv remove "$@"
            ;;
            rust:cargo)
                cargo remove "$@"
            ;;
            go:go)
                for pkg in "$@"; do go get "${pkg}@none" || return; done
                go mod tidy
            ;;
            zig:zig)
                err "Unsupported dependency remove for Zig project"
            ;;
            mojo:pixi)
                pixi remove "$@"
            ;;
            mojo:mojo)
                err "Unsupported dependency remove for Mojo project without Pixi"
            ;;
            cpp:xmake)
                [[ -f xmake.lua ]] || { err "Missing xmake.lua"; return; }

                for pkg in "$@"; do

                    sed -i.bak \
                        -e "/^[[:space:]]*add_requires([\"']${pkg}[\"']).*$/d" \
                        -e "/^[[:space:]]*add_packages([\"']${pkg}[\"']).*$/d" \
                        xmake.lua || return

                    rm -f xmake.lua.bak

                    xmake require --uninstall "${pkg}" >/dev/null 2>&1 || true
                    xmake require --clean "${pkg}" >/dev/null 2>&1 || true

                done
            ;;
            cmake:cmake)
                err "Unsupported dependency remove for CMake project"
            ;;
            bun:bun)
                bun remove "$@"
            ;;
            node:pnpm)
                pnpm remove "$@"
            ;;
            node:yarn)
                yarn remove "$@"
            ;;
            node:npm)
                npm uninstall "$@"
            ;;
            node:node)
                npm uninstall "$@"
            ;;
            dotnet:dotnet)
                for pkg in "$@"; do dotnet remove package "${pkg}" || return; done
            ;;
            java:maven)
                err "Maven dependencies must be removed from pom.xml"
            ;;
            java:gradle)
                err "Gradle dependencies must be removed from build.gradle"
            ;;
            *)
                err "Unsupported project type"
            ;;
        esac

    )

}

run () {

    (
        local file=""
        cdroot || return

        case "$(lang)" in
            lua:lua)
                file="$(entry lua)" || { err "Missing Lua entry"; return; }
                lua "${file}" "$@"
            ;;
            sh:bash)
                file="$(entry sh)" || { err "Missing Bash entry"; return; }
                bash "${file}" "$@"
            ;;
            php:php)
                file="$(entry php)" || { err "Missing PHP entry"; return; }
                php "${file}" "$@"
            ;;
            php:laravel)
                [[ -d vendor ]] || build || return
                php artisan "$@"
            ;;
            python:python)
                file="$(entry py)" || { err "Missing Python entry"; return; }
                [[ -n "${VIRTUAL_ENV:-}" || -x .venv/bin/python ]] || python3 -m venv .venv || return

                if [[ -x .venv/bin/python && -z "${VIRTUAL_ENV:-}" ]]; then .venv/bin/python "${file}" "$@"
                else python "${file}" "$@"
                fi
            ;;
            python:uv)
                file="$(entry py)" || { err "Missing Python entry"; return; }
                uv run python "${file}" "$@"
            ;;
            rust:cargo)
                cargo run "$@"
            ;;
            go:go)
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
            mojo:pixi)
                file="$(entry mojo)" || { err "Missing Mojo entry"; return; }
                pixi run mojo "${file}" "$@"
            ;;
            mojo:mojo)
                file="$(entry mojo)" || { err "Missing Mojo entry"; return; }
                mojo "${file}" "$@"
            ;;
            cpp:xmake)
                xmake run "$@"
            ;;
            cmake:cmake)
                cmake -S . -B build && cmake --build build "$@" || return
                file="$(cmake-bin)" || return
                "${file}"
            ;;
            bun:bun)
                node-script-run bun dev "" "$@" || node-entry-run "$@"
            ;;
            node:pnpm)
                node-script-run pnpm dev "" "$@" || node-entry-run "$@"
            ;;
            node:yarn)
                node-script-run yarn dev "" "$@" || node-entry-run "$@"
            ;;
            node:npm)
                node-script-run npm dev "" "$@" || node-entry-run "$@"
            ;;
            node:node)
                node-entry-run "$@"
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
            *)
                err "Unsupported project type"
            ;;
        esac

    )

}
start () {

    (
        local file="" bin=""

        cdroot || return

        case "$(lang)" in
            lua:lua)
                file="$(entry lua)" || { err "Missing Lua entry"; return; }
                lua "${file}" "$@"
            ;;
            sh:bash)
                file="$(entry sh)" || { err "Missing Bash entry"; return; }
                bash "${file}" "$@"
            ;;
            php:php)
                file="$(entry php)" || { err "Missing PHP entry"; return; }
                php "${file}" "$@"
            ;;
            php:laravel)
                [[ -d vendor ]] || build || return
                php artisan serve "$@"
            ;;
            python:python)
                [[ -n "${VIRTUAL_ENV:-}" || -x .venv/bin/python ]] || python3 -m venv .venv || return

                local py="python"
                [[ -x .venv/bin/python && -z "${VIRTUAL_ENV:-}" ]] && py=".venv/bin/python"

                if [[ -f manage.py ]]; then
                    "${py}" manage.py runserver "$@"
                elif [[ -f main.py ]] && grep -qE '^[[:space:]]*app[[:space:]]*=' main.py; then
                    "${py}" -m uvicorn main:app --reload "$@"
                elif [[ -f app.py ]] && grep -qE '^[[:space:]]*app[[:space:]]*=' app.py; then
                    "${py}" -m uvicorn app:app --reload "$@"
                elif [[ -f src/main.py ]] && grep -qE '^[[:space:]]*app[[:space:]]*=' src/main.py; then
                    "${py}" -m uvicorn src.main:app --reload "$@"
                else
                    file="$(entry py)" || { err "Missing Python entry"; return; }
                    "${py}" -O "${file}" "$@"
                fi
            ;;
            python:uv)
                if [[ -f manage.py ]]; then
                    uv run python manage.py runserver "$@"
                elif [[ -f main.py ]] && grep -qE '^[[:space:]]*app[[:space:]]*=' main.py; then
                    uv run uvicorn main:app --reload "$@"
                elif [[ -f app.py ]] && grep -qE '^[[:space:]]*app[[:space:]]*=' app.py; then
                    uv run uvicorn app:app --reload "$@"
                elif [[ -f src/main.py ]] && grep -qE '^[[:space:]]*app[[:space:]]*=' src/main.py; then
                    uv run uvicorn src.main:app --reload "$@"
                else
                    file="$(entry py)" || { err "Missing Python entry"; return; }
                    uv run python -O "${file}" "$@"
                fi
            ;;
            rust:cargo)
                cargo run --release "$@"
            ;;
            go:go)
                mkdir -p build

                if [[ -f main.go ]]; then
                    go build -ldflags="-s -w" -o build/app . && ./build/app "$@"
                elif [[ -d cmd ]]; then
                    file="$(find cmd -mindepth 2 -maxdepth 2 -type f -name main.go | head -n 1)"
                    [[ -n "${file}" ]] || { err "Missing Go entry"; return; }

                    bin="build/$(basename "$(dirname "${file}")")"
                    go build -ldflags="-s -w" -o "${bin}" "./$(dirname "${file}")" && "${bin}" "$@"
                else
                    go run . "$@"
                fi
            ;;
            zig:zig)
                zig build -Doptimize=ReleaseFast run "$@"
            ;;
            mojo:pixi)
                file="$(entry mojo)" || { err "Missing Mojo entry"; return; }
                pixi run mojo "${file}" "$@"
            ;;
            mojo:mojo)
                file="$(entry mojo)" || { err "Missing Mojo entry"; return; }
                mojo "${file}" "$@"
            ;;
            cpp:xmake)
                xmake f -m release && xmake run "$@"
            ;;
            cmake:cmake)
                cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build "$@" || return
                file="$(cmake-bin)" || return
                "${file}"
            ;;
            bun:bun)
                [[ -d dist ]] || node-script-run bun build "" || true
                node-script-run bun start "" "$@" || node-script-run bun preview "" "$@" || node-entry-run "$@"
            ;;
            node:npm)
                [[ -d dist ]] || node-script-run npm build "" || true
                node-script-run npm start "" "$@" || node-script-run npm preview "" "$@" || node-entry-run "$@"
            ;;
            node:pnpm)
                [[ -d dist ]] || node-script-run pnpm build "" || true
                node-script-run pnpm start "" "$@" || node-script-run pnpm preview "" "$@" || node-entry-run "$@"
            ;;
            node:yarn)
                [[ -d dist ]] || node-script-run yarn build "" || true
                node-script-run yarn start "" "$@" || node-script-run yarn preview "" "$@" || node-entry-run "$@"
            ;;
            node:node)
                node-entry-run "$@"
            ;;
            dotnet:dotnet)
                dotnet run -c Release "$@"
            ;;
            java:maven)
                local m="mvn" main=""
                [[ -x ./mvnw ]] && m="./mvnw"

                if "${m}" help:effective-pom -q 2>/dev/null | grep -q 'spring-boot-maven-plugin'; then
                    "${m}" spring-boot:run "$@"
                    return
                fi

                main="$(find src/main/java -type f -name "*.java" 2>/dev/null | sed 's#^src/main/java/##; s#/#.#g; s#\.java$##' | head -n 1)"

                if [[ -n "${main}" ]]; then "${m}" -q compile exec:java -Dexec.mainClass="${main}" "$@"
                else "${m}" package "$@"
                fi
            ;;
            java:gradle)
                local g="gradle"
                [[ -x ./gradlew ]] && g="./gradlew"

                if "${g}" -q tasks --all 2>/dev/null | awk '{ print $1 }' | grep -Eq '(^|:)bootRun$'; then "${g}" bootRun "$@"
                elif "${g}" -q tasks --all 2>/dev/null | awk '{ print $1 }' | grep -Eq '(^|:)run$'; then "${g}" run "$@"
                else "${g}" build "$@"
                fi
            ;;
            *)
                err "Unsupported project type"
            ;;
        esac

    )

}

new () {

    (

        _rollback () {

            (( created )) || return 0

            cd .. 2>/dev/null
            rm -rf -- "${project}" 2>/dev/null

        }
        _new-common () {

            local project_name="${1:-project}" project_type="${2:-}"

            [[ -f .gitignore ]] || printf '%s\n' \
                '.idea/' \
                '.vscode/' \
                '.vs/' \
                '*.swp' \
                '*.swo' \
                '' \
                '.DS_Store' \
                'Thumbs.db' \
                '*:Zone.Identifier' \
                '' \
                'build/' \
                'dist/' \
                'out/' \
                'target/' \
                'zig-out/' \
                '' \
                '.cache/' \
                '.turbo/' \
                '.parcel-cache/' \
                '.pytest_cache/' \
                '.mypy_cache/' \
                '.ruff_cache/' \
                '.zig-cache/' \
                '__pycache__/' \
                '' \
                'node_modules/' \
                '.venv/' \
                'venv/' \
                'vendor/' \
                '' \
                '*.log' \
                '*.tmp' \
                '.env*' \
                '!.env.example' \
                '.secrets*' \
                '!.secrets.example' \
                > .gitignore

            [[ -f .editorconfig ]] || printf '%s\n' \
                'root = true' \
                '' \
                '[*]' \
                'indent_style = space' \
                'indent_size = 4' \
                'end_of_line = lf' \
                'charset = utf-8' \
                'trim_trailing_whitespace = true' \
                'insert_final_newline = true' \
                '' \
                '[*.{yml,yaml,json,md,toml}]' \
                'indent_size = 2' \
                '' \
                '[Makefile]' \
                'indent_style = tab' \
                > .editorconfig

            [[ -f .gitattributes ]] || printf '%s\n' \
                '* text=auto eol=lf' \
                '*.sh text eol=lf' \
                '*.bat text eol=crlf' \
                '*.{png,jpg,jpeg,gif,ico,pdf,zip,gz,xz} binary' \
                > .gitattributes

            [[ -f README.md ]] || printf '%s\n' \
                "# ${project_name}" \
                '' \
                "_${project_type:-Polyglot} project" \
                '' \
                '```' \
                > README.md

        }
        _new-git () {

            [[ -d .git ]] && return 0
            command -v git >/dev/null 2>&1 || return 0

            git init -q --initial-branch=main 2>/dev/null || git init -q
            git add -A 2>/dev/null
            git -c user.email=- -c user.name=- commit -q -m 'chore: initial commit' 2>/dev/null

            return 0

        }

        local input="${1:-}" name="${2:-}" type="" variant="" project="" created=0

        [[ -n "${input}" ]] || { err "Missing project type"; return; }
        [[ -n "${name}"  ]] || { err "Missing project name"; return; }

        IFS=: read -r type variant <<<"${input}"
        type="${type,,}"
        variant="${variant,,}"

        if [[ "${name}" == "." ]]; then

            project="$(basename "$(pwd -P)")"

        else

            case "${name}" in
                ''|.|..|*..*|*/*|*\\*|.*) err "Invalid project name: ${name}"; return ;;
            esac

            [[ "${name}" =~ ^[A-Za-z0-9_][A-Za-z0-9_.-]*$ ]] || { err "Invalid project name: ${name}"; return; }
            [[ ! -e "${name}" ]] || { err "Path already exists: ${name}"; return; }

            mkdir -p -- "${name}" || return
            created=1

            cd -- "${name}" || { rmdir -- "../${name}" 2>/dev/null; return; }
            project="${name}"

        fi

        case "${type}" in
            sh|shell)          type="bash" ;;
            luarocks)          type="lua" ;;
            cargo)             type="rust" ;;
            c#|csharp)         type="dotnet" ;;
            c)                 type="xmake"; variant="c" ;;
            cpp|hpp|c++|xmake) type="xmake"; variant="${variant:-c++}" ;;
            npm|pnpm|yarn)     type="node";  variant="${type}" ;;
            rn|react-native)   type="react-native" ;;
            uv|py|py3|python3) type="python" ;;
            py*-pure|pure-py*) type="python-pure" ;;
            java)
                case "${variant:-gradle}" in
                    gradle|app*) type="gradle"; variant="" ;;
                    lib|library) type="gradle"; variant="lib" ;;
                    maven)       type="maven";  variant="" ;;
                    *)           err "Unsupported java variant: ${variant}"; return ;;
                esac
            ;;
        esac
        case "${type}" in
            bash)
                printf '%s\n' \
                    '#!/usr/bin/env bash' \
                    'set -Eeuo pipefail' \
                    '' \
                    'main () {' \
                    '' \
                    "    echo \"Hello from ${project}\"" \
                    '' \
                    '}' \
                    '' \
                    'main "$@"' > main.sh

                chmod +x main.sh
            ;;
            lua)
                printf '%s\n' \
                    '' \
                    'local function main ()' \
                    '' \
                    "    print( \"Hello from ${project}\" )" \
                    '' \
                    'end' \
                    '' \
                    'main()' > main.lua

                chmod +x main.lua
            ;;
            python)
                local py=""

                case "${variant}" in
                    nogil|free|freethreaded|t) py="${PYTHON_NOGIL_VERSION:-3.13t}" ;;
                esac

                if [[ -n "${py}" ]]; then
                    uv python install "${py}" >/dev/null 2>&1 || { err "Failed to install Python ${py}"; _rollback; return; }

                    uv init --quiet --python "${py}" . "${@:3}" 2>/dev/null \
                        || uv init --python "${py}" . "${@:3}" || { err "uv init failed"; _rollback; return; }
                else
                    uv init --quiet . "${@:3}" 2>/dev/null || uv init . "${@:3}" || { err "uv init failed"; _rollback; return; }
                fi
            ;;
            python-pure)
                local py="python3"

                if [[ "${variant}" =~ ^(gil|nogil|free|t)$ ]]; then
                    [[ -x /opt/python-3.14t/bin/python3.14 ]] || { err "Python 3.14t not found."; _rollback; return; }
                    py="/opt/python-3.14t/bin/python3.14"
                fi

                "${py}" -m venv .venv || { err "venv creation failed"; _rollback; return; }

                printf '%s\n' \
                    '' \
                    'def main () -> None:' \
                    '' \
                    "    print( \"Hello from ${project}\" )" \
                    '' \
                    '' \
                    'if __name__ == "__main__":' \
                    '    main()' > main.py

                : > requirements.txt
            ;;
            php)
                local vendor="${3:-vendor/${project}}"

                composer init --no-interaction --name "${vendor}" "${@:4}" 2>/dev/null \
                    || { err "composer init failed"; _rollback; return; }

                printf '%s\n' \
                    '<?php' \
                    '' \
                    'declare( strict_types = 1 );' \
                    '' \
                    "echo \"Hello from ${project}\" . PHP_EOL;" > main.php
            ;;
            laravel)
                composer create-project --quiet laravel/laravel . "${@:3}" 2>/dev/null \
                    || { err "laravel install failed"; _rollback; return; }
            ;;
            rust)
                case "${variant}" in
                    lib)  cargo init --quiet --lib . ;;
                    *)    cargo init --quiet . ;;
                esac || { err "cargo init failed"; _rollback; return; }
            ;;
            go)
                local module="${3:-${project}}"

                go mod init "${module}" >/dev/null 2>&1 || { err "go mod init failed"; _rollback; return; }

                printf '%s\n' \
                    'package main' \
                    '' \
                    'import "fmt"' \
                    '' \
                    'func main () {' \
                    '' \
                    "    fmt.Println( \"Hello from ${project}\" )" \
                    '' \
                    '}' > main.go
            ;;
            zig)
                zig init >/dev/null 2>&1 || { err "zig init failed"; _rollback; return; }
            ;;
            mojo)
                command -v pixi >/dev/null 2>&1 || { err "pixi not installed"; _rollback; return; }

                pixi init --quiet . \
                    -c https://conda.modular.com/max-nightly/ \
                    -c conda-forge \
                    >/dev/null 2>&1 || pixi init . \
                        -c https://conda.modular.com/max-nightly/ \
                        -c conda-forge \
                    || { err "pixi init failed"; _rollback; return; }

                pixi add mojo --quiet >/dev/null 2>&1 \
                    || pixi add mojo || { err "pixi add mojo failed"; _rollback; return; }

                printf '%s\n' \
                    'def main():' \
                    "    print( \"Hello from ${project}\" )" > main.mojo
            ;;
            xmake)
                xmake create -f -P . -l "${variant:-c++}" -t console "${project}" >/dev/null 2>&1 \
                    || { err "xmake create failed"; _rollback; return; }
            ;;
            cmake)
                local std="" lang="" ext=""

                case "${variant}" in
                    c)   std="11"; lang="C";   ext="c"   ;;
                    *)   std="17"; lang="CXX"; ext="cpp" ;;
                esac

                mkdir -p src

                printf '%s\n' \
                    'cmake_minimum_required( VERSION 3.16 )' \
                    '' \
                    "project( ${project} ${lang} )" \
                    '' \
                    "set( CMAKE_${lang}_STANDARD ${std} )" \
                    "set( CMAKE_${lang}_STANDARD_REQUIRED ON )" \
                    "set( CMAKE_${lang}_EXTENSIONS OFF )" \
                    '' \
                    "add_executable( ${project} src/main.${ext} )" \
                    > CMakeLists.txt

                if [[ "${ext}" == "c" ]]; then

                    printf '%s\n' \
                        '#include <stdio.h>' \
                        '' \
                        'int main () {' \
                        '' \
                        "    printf( \"Hello from ${project}\\n\" );" \
                        '    return 0;' \
                        '' \
                        '}' > src/main.c

                else

                    printf '%s\n' \
                        '#include <iostream>' \
                        '' \
                        'int main () {' \
                        '' \
                        "    std::cout << \"Hello from ${project}\\n\";" \
                        '    return 0;' \
                        '' \
                        '}' > src/main.cpp

                fi
            ;;
            bun)
                bun init -y >/dev/null 2>&1 || { err "bun init failed"; _rollback; return; }
            ;;
            node)
                case "${variant:-npm}" in
                    bun)
                        bun init -y >/dev/null 2>&1 || { err "bun init failed"; _rollback; return; }
                    ;;
                    pnpm)
                        pnpm init >/dev/null 2>&1 || { err "pnpm init failed"; _rollback; return; }

                        printf '%s\n' \
                            "console.log( \"Hello from ${project}\" );" > index.js
                    ;;
                    yarn)
                        yarn init -y >/dev/null 2>&1 || { err "yarn init failed"; _rollback; return; }
                        yarn install >/dev/null 2>&1 || { err "yarn install failed"; _rollback; return; }

                        printf '%s\n' \
                            "console.log( \"Hello from ${project}\" );" > index.js
                    ;;
                    npm)
                        npm init -y >/dev/null 2>&1 || { err "npm init failed"; _rollback; return; }

                        printf '%s\n' \
                            "console.log( \"Hello from ${project}\" );" > index.js
                    ;;
                    node|pure)
                        printf '%s\n' \
                            "console.log( \"Hello from ${project}\" );" > index.js
                    ;;
                    *)
                        err "Unsupported node package manager: ${variant}"
                        _rollback
                        return
                    ;;
                esac
            ;;
            react)
                case "${variant:-npm}" in
                    bun)
                        bun create vite@latest . --template react-ts --no-interactive >/dev/null 2>&1 || { err "react scaffold failed"; _rollback; return; }
                        bun install >/dev/null 2>&1 || { err "bun install failed"; _rollback; return; }
                    ;;
                    pnpm)
                        pnpm create vite@latest . --template react-ts --no-interactive >/dev/null 2>&1 || { err "react scaffold failed"; _rollback; return; }
                        pnpm install >/dev/null 2>&1 || { err "pnpm install failed"; _rollback; return; }
                    ;;
                    yarn)
                        yarn create vite . --template react-ts --no-interactive >/dev/null 2>&1 || { err "react scaffold failed"; _rollback; return; }
                        yarn install >/dev/null 2>&1 || { err "yarn install failed"; _rollback; return; }
                    ;;
                    npm)
                        npx --yes create-vite@latest . --template react-ts --no-interactive >/dev/null 2>&1 || { err "react scaffold failed"; _rollback; return; }
                        npm install --silent --no-fund --no-audit >/dev/null 2>&1 || { err "npm install failed"; _rollback; return; }
                    ;;
                    *)
                        err "Unsupported react package manager: ${variant}"
                        _rollback
                        return
                    ;;
                esac
            ;;
            react-native)
                case "${variant:-npm}" in
                    bun)
                        bun x create-expo-app@latest . --yes \
                            >/dev/null 2>&1 || { err "react-native scaffold failed"; _rollback; return; }
                    ;;
                    pnpm)
                        pnpm dlx create-expo-app@latest . --yes \
                            >/dev/null 2>&1 || { err "react-native scaffold failed"; _rollback; return; }
                    ;;
                    yarn)
                        yarn dlx create-expo-app@latest . --yes \
                            >/dev/null 2>&1 || { err "react-native scaffold failed"; _rollback; return; }
                    ;;
                    npm)
                        npx --yes create-expo-app@latest . --yes \
                            >/dev/null 2>&1 || { err "react-native scaffold failed"; _rollback; return; }
                    ;;
                    *)
                        err "Unsupported react-native package manager: ${variant}"
                        _rollback
                        return
                    ;;
                esac
            ;;
            next)
                local pm="${variant:-npm}"
                local -a cmd=()

                case "${pm}" in
                    bun)  cmd=( bun create next-app@latest ) ;;
                    pnpm) cmd=( pnpm create next-app@latest ) ;;
                    yarn) cmd=( yarn create next-app ) ;;
                    npm)  cmd=( npx --yes create-next-app@latest ) ;;
                    *)    err "Unsupported next package manager: ${pm}"; _rollback; return ;;
                esac

                "${cmd[@]}" . \
                    --yes \
                    --typescript \
                    --tailwind \
                    --eslint \
                    --app \
                    --src-dir \
                    --no-import-alias \
                    --no-turbopack \
                    >/dev/null 2>&1 || { err "create-next-app failed"; _rollback; return; }
            ;;
            astro)
                case "${variant:-npm}" in
                    bun)
                        bunx create-astro@latest . \
                            --template minimal --install --no-git --skip-houston --yes \
                            >/dev/null 2>&1 || { err "astro scaffold failed"; _rollback; return; }
                    ;;
                    pnpm)
                        pnpm dlx create-astro@latest . \
                            --template minimal --install --no-git --skip-houston --yes \
                            >/dev/null 2>&1 || { err "astro scaffold failed"; _rollback; return; }
                    ;;
                    yarn)
                        yarn create astro . \
                            --template minimal --install --no-git --skip-houston --yes \
                            >/dev/null 2>&1 || { err "astro scaffold failed"; _rollback; return; }
                    ;;
                    npm)
                        npm create astro@latest . -- \
                            --template minimal --install --no-git --skip-houston --yes \
                            >/dev/null 2>&1 || { err "astro scaffold failed"; _rollback; return; }
                    ;;
                    *)
                        err "Unsupported astro package manager: ${variant}"
                        _rollback
                        return
                    ;;
                esac
            ;;
            dotnet)
                local tpl="${variant:-console}"

                case "${tpl}" in
                    api) tpl="webapi"   ;;
                    lib) tpl="classlib" ;;
                esac

                dotnet new "${tpl}" --name "${project}" --output . --force >/dev/null 2>&1 \
                    || { err "dotnet new ${tpl} failed"; _rollback; return; }
            ;;
            maven)
                local groupId="${3:-com.example}"
                [[ "${name}" == "." ]] && { err "maven requires a named project (cannot use '.')"; return; }

                cd .. || { _rollback; return; }
                rmdir -- "${project}" 2>/dev/null

                mvn -q archetype:generate -DgroupId="${groupId}" -DartifactId="${project}" \
                    -DarchetypeArtifactId=maven-archetype-quickstart \
                    -DinteractiveMode=false 2>/dev/null \
                    || { err "maven archetype failed"; rm -rf -- "${project}" 2>/dev/null; return; }

                cd -- "${project}" || return
            ;;
            gradle)
                local tpl=""
                local -a args=()

                case "${variant}" in
                    *lib*) tpl="java-library" ;;
                    *)     tpl="java-application" ;;
                esac

                args=( --type "${tpl}" --project-name "${project}" --dsl kotlin --use-defaults --no-incubating --quiet )

                case "${tpl}" in
                    java-*|kotlin-*|groovy-*|scala-*) args+=( --test-framework junit-jupiter ) ;;
                esac

                gradle init "${args[@]}" 2>/dev/null || { err "gradle init failed"; _rollback; return; }
            ;;
            *)
                err "Unsupported project type: ${type}"
                _rollback
                return
            ;;
        esac

        _new-common "${project}" "${type}"
        _new-git

        succ "Created ${type}${variant:+:${variant}} → ${project}"

    )

}
