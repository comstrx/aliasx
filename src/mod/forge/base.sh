
caches () {

    cat <<-EOF
	.cache
	.coverage
	.DS_Store
	.eslintcache
	.mypy_cache
	.next
	.nox
	.nuxt
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
	CMakeCache.txt
	compile_commands.json
	coverage
	htmlcov
	node_modules/.cache
	bootstrap/cache/*.php
	storage/framework/cache/data/*
	storage/framework/views/*
	!storage/framework/cache/data/.gitignore
	!storage/framework/views/.gitignore
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
	.claude
	.codex
	.dart_tool
	.eggs
	.expo
	.flutter-plugins
	.flutter-plugins-dependencies
	.gradle
	.idea
	.lua
	.mojo
	.mojopkg
	.mvn
	.node_modules
	.npm
	.output
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
	.bin
	bower_components
	build
	cmake-build-*
	CMakeFiles
	corpus
	criterion
	dist
	env
	luarocks
	lua_modules
	node_modules
	obj
	out
	pip-wheel-metadata
	public/build
	public/hot
	public/storage
	storage/*.key
	target
	tmp
	vendor
	venv
	wheels
	xmake-build
	zig-out
	.tmp
	.temp
	.Trashes
	.Spotlight-V100
	*.bak
	*.cache
	*.egg-info
	*.exe
	*.gcda
	*.gcno
	*.gcov
	*.lcov
	*.log
	*.o
	*.obj
	*.orig
	*.out
	*.pyd
	*.profdata
	*.profraw
	*.rs.bk
	*.rs.tmp
	*.so
	*.swp
	*.swo
	*.test
	*.tsbuildinfo
	*~
	.nyc_output
	.phpactor.json
	.phpunit.cache
	artifacts
	clover.xml
	cobertura.xml
	codecov.json
	composer.phar
	coverage.out
	Desktop.ini
	ehthumbs.db
	lcov.info
	llvm-cov.json
	perf.data*
	EOF

}
gitignores () {

    ignores

    cat <<-EOF
	.git
	.env*
	.var*
	.secret*
	!.env*.sample
	!.env*.example
	!.env*.template
	!.var*.sample
	!.var*.example
	!.var*.template
	!.secret*.sample
	!.secret*.example
	!.secret*.template
	npm-debug.log*
	yarn-debug.log*
	yarn-error.log*
	pnpm-debug.log*
	lerna-debug.log*
	Homestead.*
	storage/logs/*
	storage/app/livewire-tmp/*
	storage/framework/sessions/*
	storage/app/private/*
	storage/app/public/*
	!storage/logs/.gitignore
	!storage/app/livewire-tmp/.gitignore
	!storage/framework/sessions/.gitignore
	!storage/app/private/.gitignore
	!storage/app/public/.gitignore
	.pnp.*
	*.pem
	*.key
	*.p12
	*.pfx
	*.crt
	*.cer
	*.cosign.sig
	*.cosign.crt
	*.cosign.bundle
	EOF

}
dockerignores () {

    gitignores

    cat <<-EOF
	docker-deploy.sh
	docker-compose.yml
	docker-compose.yaml
	docker-compose.*.yml
	docker-compose.*.yaml
	EOF

}
editorconfigs () {

    cat <<-'EOF'
	root = true

	[*]
	charset = utf-8
	end_of_line = lf
	indent_style = space

	indent_size = 4
	tab_width = 4
	max_line_length = off

	insert_final_newline = true
	trim_trailing_whitespace = true

	[*.md]
	trim_trailing_whitespace = false

	[*.{yml,yaml}]
	indent_size = 2
	EOF

}
gitattributes () {

    cat <<-'EOF'
	*           text=auto eol=lf
	*.sh        text eol=lf
	*.bash      text eol=lf
	*.zsh       text eol=lf
	*.rs        text eol=lf
	*.toml      text eol=lf
	*.yml       text eol=lf
	*.yaml      text eol=lf
	*.json      text eol=lf
	*.md        text eol=lf
	*.txt       text eol=lf
	*.ini       text eol=lf
	*.cfg       text eol=lf
	*.conf      text eol=lf
	*.env       text eol=lf
	*.mk        text eol=lf
	*.js        text eol=lf
	*.mjs       text eol=lf
	*.cjs       text eol=lf
	*.ts        text eol=lf
	*.tsx       text eol=lf
	*.jsx       text eol=lf
	*.css       text eol=lf
	*.scss      text eol=lf
	*.sass      text eol=lf
	*.html      text eol=lf
	*.svg       text eol=lf
	*.ps1       text eol=lf
	*.rb        text eol=lf
	*.py        text eol=lf
	*.go        text eol=lf
	*.frag      text eol=lf
	*.vert      text eol=lf
	*.wgsl      text eol=lf
	*.sln       text eol=crlf
	*.bat       text eol=crlf
	*.cmd       text eol=crlf
	*.png       binary
	*.jpg       binary
	*.jpeg      binary
	*.gif       binary
	*.webp      binary
	*.ico       binary
	*.pdf       binary
	*.ttf       binary
	*.otf       binary
	*.woff      binary
	*.woff2     binary
	*.zip       binary
	*.tar       binary
	*.gz        binary
	*.tgz       binary
	*.7z        binary
	*.rar       binary
	*.wasm      binary
	*.exe       binary
	*.dll       binary
	*.so        binary
	*.dylib     binary
	*.a         binary
	*.lib       binary
	*.pdb       binary
	*.mp3       binary
	*.mp4       binary
	*.mov       binary
	*.mkv       binary
	*.wav       binary
	*.pem       binary
	*.key       binary
	*.p12       binary
	*.pfx       binary
	*.min.js    -diff
	*.min.css   -diff
	*.map       -diff
	Cargo.lock          text eol=lf
	package-lock.json   text eol=lf
	pnpm-lock.yaml      text eol=lf
	yarn.lock           text eol=lf
	Dockerfile          text eol=lf
	Makefile            text eol=lf
	*.isle              linguist-language=Lisp
	dist/**             linguist-generated=true
	build/**            linguist-generated=true
	generated/**        linguist-generated=true
	EOF

}

root () {

    local git_root="" dir="" marker=""

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

    git_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
    dir="$(pwd -P)"

    while true; do

        for marker in "${files[@]}"; do
            [[ -f "${dir}/${marker}" ]] && { out "${dir}"; return; }
        done
        for marker in "${globs[@]}"; do
            compgen -G "${dir}/${marker}" >/dev/null && { out "${dir}"; return; }
        done

        [[ "${dir}" == "${git_root}" ]] && break
        [[ "${dir}" == "/" ]] && break

        dir="$(dirname -- "${dir}")"

    done

    [[ -n "${git_root}" ]] && { out "${git_root}"; return; }

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
        local ext="${1:-}" dir="" file="" ignore="" suffix="" name=""
        local -a entries=() files=() args=() targets=()

        dir="$(root)" || return
        name="$(basename "${dir}")"

        cd "${dir}" || return

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
                "public/main.${suffix}"
                "public/run.${suffix}"
                "lib/main.${suffix}"
                "lib/index.${suffix}"
            )

            for file in "${entries[@]}"; do
                [[ -f "${file}" ]] && { out "${dir}/${file}"; return; }
            done

            if [[ -d bin ]]; then

                while IFS= read -r -d '' file; do
                    files+=( "${file#./}" )
                done < <(find bin -maxdepth 1 -type f -name "*.${suffix}" -print0 2>/dev/null)

                case "${#files[@]}" in
                    1) out "${dir}/${files[0]}"; return ;;
                    0) ;;
                    *) return ;;
                esac

                files=()

            fi

            args+=( -name "*.${suffix}" )

        else

            targets=(
                main.* index.* run.* src/main.* src/index.* src/run.* public/index.* public/run.*
                lib/main.* bin/main.* bin/"${name}".* bin/"${name//-/_}".*
            )

            for file in "${targets[@]}"; do
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
python-bin () {

    case "$(lang)" in
        python:uv)
            out "uv run python"
        ;;
        python:python)
            if [[ -n "${VIRTUAL_ENV:-}" ]]; then
                out "${VIRTUAL_ENV}/bin/python"
            elif [[ -x .venv/bin/python ]]; then
                out ".venv/bin/python"
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
flask-start () {

    local app="${1:-}"
    local -a runner=() user=()

    [[ -n "${app}" ]] || return
    shift 2>/dev/null || true

    while [[ $# -gt 0 && "$1" != "--" ]]; do runner+=( "$1" ); shift; done

    [[ "${1:-}" == "--" ]] && shift
    [[ "${#runner[@]}" -gt 0 ]] || return

    user=( "$@" )

    if "${runner[@]}" -c 'import gunicorn' 2>/dev/null; then
        "${runner[@]}" -m gunicorn "${app}:app" "${user[@]}"
    else
        "${runner[@]}" -m flask --app "${app}" run "${user[@]}"
    fi

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

        [[ -f package.json ]] || return

        if command -v jq >/dev/null 2>&1; then
            [[ -n "$(jq -r --arg n "${name}" '.scripts[$n] // empty' package.json 2>/dev/null)" ]] || return
        else
            grep -Eq "\"${name}\"[[:space:]]*:" package.json || return
        fi

    )

}
node-script () {

    (
        local pm="${1:-}" name="${2:-}"

        [[ -n "${pm}"   ]] || return
        [[ -n "${name}" ]] || return

        cdroot || return
        node-has "${name}" || return

        [[ -d node_modules ]] || "${pm}" install || return

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
            bun:bun) bun "${file}" "$@" ;;
            *) node "${file}" "$@" ;;
        esac

    else

        err "Missing Node entry"

    fi

}
node-check () {

    local file=""

    if file="$(entry js 2>/dev/null)"; then

        node --check "${file}"
        return

    fi
    if file="$(entry ts 2>/dev/null)"; then

        local tsc=""

        if [[ -x node_modules/.bin/tsc ]]; then tsc="node_modules/.bin/tsc"
        elif command -v tsc >/dev/null 2>&1; then tsc="tsc"
        else err "Missing tsc"; return
        fi

        if [[ -f tsconfig.json ]]; then "${tsc}" --noEmit
        else "${tsc}" --noEmit "${file}"
        fi

        return

    fi

    err "Missing Node entry"

}
