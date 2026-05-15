
caches () {

    cat <<-EOF
	.cache
	.coverage
	.DS_Store
	.eslintcache
	.mypy_cache
	.next/cache
	.nox
	.nuxt
	.output
	.parcel-cache
	.phpunit.result.cache
	.pyre
	.pytest_cache
	.ruff_cache
	.svelte-kit
	.tox
	.turbo
	.vite
	.zig-cache
	__pycache__
	bootstrap/cache/*.php
	CMakeCache.txt
	CMakeFiles
	compile_commands.json
	coverage
	htmlcov
	node_modules/.cache
	public/build
	storage/framework/cache/data/*
	storage/framework/views/*
	Thumbs.db
	xmake-cache
	zig-cache
	*.pyc
	*:Zone.Identifier
	EOF

}
ignores () {

    caches

    cat <<-EOF
	.dart_tool
	.eggs
	.expo
	.flutter-plugins
	.flutter-plugins-dependencies
	.gradle
	.hg
	.idea
	.lua
	.mojo
	.mojopkg
	.mvn
	.next
	.node_modules
	.npm
	.pixi
	.pnpm-store
	.pub-cache
	.svn
	.venv
	.vercel
	.vs
	.vscode
	.xmake
	.xmake_cache
	.yarn
	bin
	bower_components
	build
	cmake-build-*
	dist
	luarocks
	lua_modules
	node_modules
	obj
	public/storage
	storage/framework/sessions/*
	storage/logs/*.log
	target
	vendor
	venv
	xmake-build
	zig-out
	*.egg-info
	*.exe
	*.log
	*.o
	*.obj
	*.out
	*.so
	EOF

}

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
        pubspec.yaml
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
        src/main.dart
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
        main.dart
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

    dir="$(git rev-parse --show-toplevel 2>/dev/null)" && { out "${dir}"; return; }

    out "$(pwd -P)"

}
cdroot () {

    cd "$(root)" || return

}
lang () {

    (
        cdroot || return

        if   [[ -f artisan ]]; then out php:laravel
        elif [[ -f composer.json ]]; then out php:php

        elif [[ -f Cargo.toml ]]; then out rust:cargo
        elif [[ -f go.mod ]]; then out go:go
        elif [[ -f build.zig ]]; then out zig:zig

        elif [[ -f pubspec.yaml ]] && grep -qE '^[[:space:]]*flutter:' pubspec.yaml; then out dart:flutter
        elif [[ -f pubspec.yaml ]]; then out dart:dart

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
        elif [[ -f pnpm-lock.yaml ]]; then out node:pnpm
        elif [[ -f yarn.lock ]]; then out node:yarn
        elif [[ -f package.json ]]; then

            if command -v jq >/dev/null 2>&1; then

                case "$(jq -r '.packageManager // empty' package.json 2>/dev/null)" in
                    pnpm@*) out node:pnpm; return ;;
                    yarn@*) out node:yarn; return ;;
                    bun@*)  out bun:bun;   return ;;
                esac

            fi

            out node:npm

        elif [[ -f main.php  || -f index.php || -f run.php || -f src/main.php  || -f src/index.php || -f src/run.php || -f public/index.php || -f public/run.php ]]; then out php:php
        elif [[ -f main.py   || -f index.py  || -f run.py  || -f src/main.py   || -f src/index.py  || -f src/run.py  ]]; then out python:python
        elif [[ -f main.ts   || -f index.ts  || -f run.ts  || -f src/main.ts   || -f src/index.ts  || -f src/run.ts  ]]; then out node:node
        elif [[ -f main.js   || -f index.js  || -f run.js  || -f src/main.js   || -f src/index.js  || -f src/run.js  ]]; then out node:node
        elif [[ -f main.lua  || -f index.lua || -f run.lua || -f src/main.lua  || -f src/index.lua || -f src/run.lua ]]; then out lua:lua
        elif [[ -f main.sh   || -f index.sh  || -f run.sh  || -f src/main.sh   || -f src/index.sh  || -f src/run.sh  ]]; then out sh:bash
        elif [[ -f main.dart || -f src/main.dart || -f lib/main.dart ]]; then out dart:dart

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
                "main.${suffix}"
                "index.${suffix}"
                "run.${suffix}"
                "src/main.${suffix}"
                "src/index.${suffix}"
                "src/run.${suffix}"
                "public/index.${suffix}"
                "public/run.${suffix}"
                "lib/main.${suffix}"
            )

            for file in "${entries[@]}"; do
                [[ -f "${file}" ]] && { out "${dir}/${file}"; return; }
            done

            args+=( -name "*.${suffix}" )

        else

            for file in main.* index.* run.* src/main.* src/index.* src/run.* public/index.* public/run.* lib/main.*; do
                [[ -f "${file}" ]] && { out "${dir}/${file}"; return; }
            done

            args+=( \( \
                -name "*.py"   -o -name "*.js"   -o -name "*.ts"   -o -name "*.php"  \
                -o -name "*.sh" -o -name "*.lua" -o -name "*.rs"   -o -name "*.go"   \
                -o -name "*.cpp" -o -name "*.c"  -o -name "*.zig"  -o -name "*.mojo" \
                -o -name "*.dart" \
            \) )

        fi

        while IFS= read -r ignore; do

            [[ -n "${ignore}" ]] || continue

            case "${ignore}" in
                */*)               args+=( -not -path "./${ignore}" ) ;;
                *'*'*|*'?'*|*'['*) args+=( -not -name "${ignore}" ) ;;
                *)                 args+=( -not -path "./${ignore}" -not -path "./${ignore}/*" ) ;;
            esac

        done < <(ignores)

        while IFS= read -r -d '' file; do
            files+=( "${file#./}" )
        done < <(find . -type f "${args[@]}" -print0 2>/dev/null)

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
                | sort | head -n 1
        )"

        [[ -n "${file}" ]] && { out "${file}"; return; }

    done

    err "Missing CMake executable"

}
py-bin () {

    case "$(lang)" in
        python:uv)
            out "uv run python"
        ;;
        python:python)
            if [[ -n "${VIRTUAL_ENV:-}" ]]; then out "${VIRTUAL_ENV}/bin/python"
            elif [[ -x .venv/bin/python ]]; then out ".venv/bin/python"
            else
                python3 -m venv .venv >/dev/null 2>&1 || { err "venv creation failed"; return; }
                out ".venv/bin/python"
            fi
        ;;
        *)
            err "Not a Python project"
        ;;
    esac

}
node-bin () {

    case "$(lang)" in
        bun:bun)   out bun ;;
        node:pnpm) out pnpm ;;
        node:yarn) out yarn ;;
        node:npm)  out npm ;;
        node:node) out node ;;
        *)         err "Not a Node project" ;;
    esac

}
node-has () {

    (
        local name="${1:-}"

        [[ -n "${name}" ]] || return

        cdroot || return
        ensure jq || return

        [[ -f package.json ]] || return
        [[ -n "$(jq -r --arg n "${name}" '.scripts[$n] // empty' package.json 2>/dev/null)" ]] || return

    )

}

node-script () {

    (
        local pm="${1:-}" name="${2:-}"

        [[ -n "${pm}"   ]] || return
        [[ -n "${name}" ]] || return

        cdroot || return
        node-has "${name}" || return

        [[ -d node_modules ]] || "${pm}" install >/dev/null 2>&1 || return

        case "${pm}" in
            bun)  bun  run "${name}" "${@:3}" ;;
            pnpm) pnpm run "${name}" "${@:3}" ;;
            yarn) yarn     "${name}" "${@:3}" ;;
            npm)  npm  run "${name}" "${@:3}" ;;
            *)    return ;;
        esac

    )

}
node-entry () {

    local file="" kind=""

    kind="$(lang)" 2>/dev/null

    if file="$(entry ts 2>/dev/null)"; then

        case "${kind}" in
            bun:bun)
                ensure bun || return
                bun "${file}" "$@"
            ;;
            *)
                if   command -v tsx >/dev/null 2>&1; then tsx "${file}" "$@"
                elif command -v bun >/dev/null 2>&1; then bun "${file}" "$@"
                else err "Missing tsx or bun for TypeScript entry"
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

    fi

}
node-check () {

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
