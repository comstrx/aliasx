
root () {

    local dir="" marker=""

    local -a markers=(
        artisan
        composer.json
        Cargo.toml
        xmake.lua
        go.mod
        pyproject.toml
        requirements.txt
        CMakeLists.txt
        package.json
        bun.lock
        bun.lockb
        src/main.lua
        src/main.sh
        main.lua
        main.sh
        index.lua
        index.sh
        run.lua
        run.sh
    )

    dir="$(git rev-parse --show-toplevel 2>/dev/null)" && { out "${dir}"; return 0; }
    for marker in "${markers[@]}"; do [[ -f "${marker}" ]] && { out "$(pwd -P)"; return 0; }; done

    dir="${PWD:-.}"

    while [[ "${dir}" != "/" ]]; do
        for marker in "${markers[@]}"; do [[ -f "${dir}/${marker}" ]] && { out "${dir}"; return 0; }; done
        dir="$(dirname "${dir}")"
    done

    out "$(pwd -P)"

}
cdroot () {

    cd "$(root)" || { err "cannot cd project root"; return 1; }

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
	*.log
	*.o
	*.so
	*.obj
	*.out
	*.exe
	*.egg-info
	__pycache__
	bootstrap/cache
	bower_components
	cmake-build-*
	CMakeCache.txt
	CMakeFiles
	compile_commands.json
	coverage
	luarocks
	lua_modules
	node_modules
	Thumbs.db
	xmake-build
	xmake-cache
	public/storage
	storage/framework/cache
	storage/framework/sessions
	storage/framework/views
	storage/logs
	bin
	build
	dist
	obj
	target
	vendor
	venv
	EOF

}
entry () {

    (
        local ext="${1:-}" dir="" file="" ignore=""
        local -a files=() args=()

        [[ -n "${ext}" ]] || return 1
        ext="${ext#.}"

        dir="$(root)" || return 1
        cdroot || return 1

        for file in "main.${ext}" "index.${ext}" "run.${ext}" "src/main.${ext}" "public/index.${ext}"; do
            [[ -f "${file}" ]] && { out "${dir}/${file}"; return 0; }
        done

        while IFS= read -r ignore; do
            [[ -n "${ignore}" ]] && args+=( -not -path "./${ignore}" -not -path "./${ignore}/*" )
        done < <(ignores)

        while IFS= read -r -d '' file; do
            files+=( "${file#./}" );
        done < <(find . -type f -name "*.${ext}" "${args[@]}" -print0 2>/dev/null)

        [[ "${#files[@]}" -eq 1 ]] || return 1
        out "${dir}/${files[0]}"

    )

}
lang () {

    (
        cdroot || return 1

        if [[ -f artisan ]]; then out php:laravel
        elif [[ -f composer.json ]]; then out php:php
        elif [[ -f Cargo.toml ]]; then out rust:cargo
        elif [[ -f go.mod ]]; then out go:go
        elif [[ -f xmake.lua ]]; then out cpp:xmake
        elif [[ -f pyproject.toml ]]; then out python:uv
        elif [[ -f requirements.txt ]]; then out python:python
        elif [[ -f bun.lock || -f bun.lockb ]]; then out node:bun
        elif [[ -f pnpm-lock.yaml ]]; then out node:pnpm
        elif [[ -f yarn.lock ]]; then out node:yarn
        elif [[ -f package.json ]]; then out node:npm
        elif [[ -f CMakeLists.txt ]]; then out cmake:cmake
        elif [[ -f main.php || -f index.php || -f run.php || -f src/main.php || -f public/index.php ]]; then out php:php
        elif [[ -f main.py || -f index.py || -f run.py || -f src/main.py ]]; then out python:python
        elif [[ -f main.lua || -f index.lua || -f run.lua || -f src/main.lua ]]; then out lua:lua
        elif [[ -f main.sh || -f index.sh || -f run.sh || -f src/main.sh ]]; then out sh:bash
        else return 1
        fi
    )

}

nrun () {

    local tool="${1:-}" name="${2:-}" fallback="${3:-}"

    [[ -f package.json ]] || return 1

    if command -v node >/dev/null 2>&1 && node -e "process.exit(require('./package.json').scripts?.['${name}'] ? 0 : 1)" 2>/dev/null; then

        case "${tool}" in
            bun)  bun run "${name}" "${@:4}" ;;
            pnpm) pnpm run "${name}" "${@:4}" ;;
            yarn) yarn "${name}" "${@:4}" ;;
            npm)  npm run "${name}" "${@:4}" ;;
        esac

    elif [[ -n "${fallback}" ]]; then

        case "${tool}" in
            bun)  bun "${fallback}" "${@:4}" ;;
            pnpm) pnpm "${fallback}" "${@:4}" ;;
            yarn) yarn "${fallback}" "${@:4}" ;;
            npm)  npm "${fallback}" "${@:4}" ;;
        esac

    else

        return 1

    fi

}
clean () {

    (
        local ignore=""
        local -a args=()

        cdroot || return 1

        while IFS= read -r ignore; do
            [[ -n "${ignore}" ]] && args+=( -path "./${ignore}" -o -path "./${ignore}/*" -o )
        done < <(ignores)

        [[ "${#args[@]}" -gt 0 ]] || return 0
        unset 'args[${#args[@]}-1]'

        find . \( "${args[@]}" \) -prune -exec rm -rf {} + 2>/dev/null
        find . -type f -name "*:Zone.Identifier" -delete 2>/dev/null

    )

    succ "Cleaned"

}
check () {

    (
        cdroot || return 1

        case "$(lang)" in
            *:lua)     luac -p "$(entry lua)" ;;
            *:bash)    find . -type f -name "*.sh" -print0 | xargs -0 shellcheck -x -e SC2148 ;;
            *:python)  python -m compileall -q . ;;
            *:uv)      uv run python -m compileall -q . ;;
            *:php)     find . -type f -name "*.php" -not -path "./vendor/*" -print0 | xargs -0 -n1 php -l ;;
            *:bun)     nrun bun  lint "" "$@" || nrun bun build "" "$@" ;;
            *:pnpm)    nrun pnpm lint "" "$@" || nrun pnpm build "" "$@" ;;
            *:yarn)    nrun yarn lint "" "$@" || nrun yarn build "" "$@" ;;
            *:npm)     nrun npm  lint "" "$@" || nrun npm build "" "$@" ;;
            *:cmake)   cmake -S . -B build && cmake --build build "$@" ;;
            *:xmake)   xmake check "$@" ;;
            *:laravel) php artisan test "$@" ;;
            *:cargo)   cargo check "$@" ;;
            *:go)      go test ./... "$@" ;;
            *)         err "Unsupported project type"; return 1 ;;
        esac
    )

}
tests () {

    (
        cdroot || return 1

        case "$(lang)" in
            *:lua)     lua test.lua "$@" || luac -p "$(entry lua)" ;;
            *:bash)    find . -type f -name "*.sh" -print0 | xargs -0 shellcheck -x -e SC2148 ;;
            *:python)  python -m pytest "$@" ;;
            *:uv)      uv run pytest "$@" ;;
            *:php)     vendor/bin/phpunit "$@" ;;
            *:bun)     nrun bun  test test "$@" ;;
            *:pnpm)    nrun pnpm test test "$@" ;;
            *:yarn)    nrun yarn test test "$@" ;;
            *:npm)     nrun npm  test test "$@" ;;
            *:cmake)   cmake -S . -B build && cmake --build build && ctest --test-dir build "$@" ;;
            *:xmake)   xmake test "$@" ;;
            *:laravel) php artisan test "$@" ;;
            *:cargo)   cargo test "$@" ;;
            *:go)      go test ./... "$@" ;;
            *)         err "Unsupported project type"; return 1 ;;
        esac
    )

}
build () {

    (
        cdroot || return 1

        case "$(lang)" in
            *:lua)     luac -p "$(entry lua)" ;;
            *:bash)    find . -type f -name "*.sh" -print0 | xargs -0 shellcheck -x -e SC2148 ;;
            *:python)  python -m build "$@" ;;
            *:uv)      uv build "$@" ;;
            *:php)     composer dump-autoload -o "$@" ;;
            *:bun)     nrun bun  build "" "$@" ;;
            *:pnpm)    nrun pnpm build "" "$@" ;;
            *:yarn)    nrun yarn build "" "$@" ;;
            *:npm)     nrun npm  build "" "$@" ;;
            *:cmake)   cmake -S . -B build && cmake --build build "$@" ;;
            *:xmake)   xmake build "$@" ;;
            *:laravel) npm run build "$@" && php artisan optimize ;;
            *:cargo)   cargo build "$@" ;;
            *:go)      go build ./... "$@" ;;
            *)         err "Unsupported project type"; return 1 ;;
        esac
    )

}
build-release () {

    (
        cdroot || return 1

        case "$(lang)" in
            *:lua)     luac -p "$(entry lua)" ;;
            *:bash)    find . -type f -name "*.sh" -print0 | xargs -0 shellcheck -x -e SC2148 ;;
            *:python)  python -m build "$@" ;;
            *:uv)      uv build "$@" ;;
            *:php)     composer install --no-dev -o "$@" ;;
            *:bun)     nrun bun  build "" "$@" ;;
            *:pnpm)    nrun pnpm build "" "$@" ;;
            *:yarn)    nrun yarn build "" "$@" ;;
            *:npm)     nrun npm  build "" "$@" ;;
            *:cmake)   cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build "$@" ;;
            *:xmake)   xmake f -m release && xmake build "$@" ;;
            *:laravel) npm run build "$@" && php artisan optimize ;;
            *:cargo)   cargo build --release "$@" ;;
            *:go)      go build -ldflags="-s -w" ./... "$@" ;;
            *)         err "Unsupported project type"; return 1 ;;
        esac
    )

}
install () {

    (
        cdroot || return 1

        case "$(lang)" in
            *:lua)     luarocks make "$@" ;;
            *:bash)    chmod +x ./*.sh 2>/dev/null || true ;;
            *:python)  pip install -r requirements.txt "$@" || pip install -e . "$@" ;;
            *:uv)      uv sync "$@" ;;
            *:php)     composer install "$@" ;;
            *:bun)     bun  install "$@" ;;
            *:pnpm)    pnpm install "$@" ;;
            *:yarn)    yarn install "$@" ;;
            *:npm)     npm  install "$@" ;;
            *:cmake)   cmake -S . -B build && cmake --build build && cmake --install build "$@" ;;
            *:xmake)   xmake install "$@" ;;
            *:laravel) composer install "$@" && { [[ ! -f package.json ]] || npm install; } ;;
            *:cargo)   cargo fetch "$@" ;;
            *:go)      go mod download "$@" ;;
            *)         err "Unsupported project type"; return 1 ;;
        esac
    )

}
run () {

    (
        local file=""
        cdroot || return 1

        case "$(lang)" in
            *:lua)     file="$(entry lua)" || { err "Missing Lua entry";    return 1; }; lua "${file}" "$@" ;;
            *:bash)    file="$(entry sh)"  || { err "Missing Bash entry";   return 1; }; bash "${file}" "$@" ;;
            *:python)  file="$(entry py)"  || { err "Missing Python entry"; return 1; }; python "${file}" "$@" ;;
            *:uv)      file="$(entry py)"  || { err "Missing Python entry"; return 1; }; uv run python "${file}" "$@" ;;
            *:php)     file="$(entry php)" || { err "Missing PHP entry";    return 1; }; php "${file}" "$@" ;;
            *:bun)     nrun bun  dev start "$@" ;;
            *:pnpm)    nrun pnpm dev start "$@" ;;
            *:yarn)    nrun yarn dev start "$@" ;;
            *:npm)     nrun npm  dev start "$@" ;;
            *:cmake)   cmake -S . -B build && cmake --build build "$@" ;;
            *:xmake)   xmake run "$@" ;;
            *:laravel) php artisan "$@" ;;
            *:cargo)   cargo run "$@" ;;
            *:go)      go run . "$@" ;;
            *)         err "Unsupported project type"; return 1 ;;
        esac
    )

}
start () {

    (
        local file=""
        cdroot || return 1

        case "$(lang)" in
            *:lua)     file="$(entry lua)" || { err "Missing Lua entry";    return 1; }; lua "${file}" "$@" ;;
            *:bash)    file="$(entry sh)"  || { err "Missing Bash entry";   return 1; }; bash "${file}" "$@" ;;
            *:python)  file="$(entry py)"  || { err "Missing Python entry"; return 1; }; python -O "${file}" "$@" ;;
            *:uv)      file="$(entry py)"  || { err "Missing Python entry"; return 1; }; uv run python "${file}" "$@" ;;
            *:php)     file="$(entry php)" || { err "Missing PHP entry";    return 1; }; php "${file}" "$@" ;;
            *:bun)     nrun bun  start "" "$@" ;;
            *:pnpm)    nrun pnpm start "" "$@" ;;
            *:yarn)    nrun yarn start "" "$@" ;;
            *:npm)     nrun npm  start "" "$@" ;;
            *:cmake)   cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build "$@" ;;
            *:xmake)   xmake f -m release && xmake run "$@" ;;
            *:laravel) php artisan optimize && php artisan serve --host=0.0.0.0 --port=8000 "$@" ;;
            *:cargo)   cargo run --release "$@" ;;
            *:go)      mkdir -p build && go build -ldflags="-s -w" -o build/app . && ./build/app "$@" ;;
            *)         err "Unsupported project type"; return 1 ;;
        esac
    )

}
serve () {

    (
        cdroot || return 1

        case "$(lang)" in
            *:python)  python -m http.server "${1:-8000}" ;;
            *:uv)      uv run python -m http.server "${1:-8000}" ;;
            *:php)     if [[ -d public ]]; then php -S 0.0.0.0:8000 -t public "$@"; else php -S 0.0.0.0:8000 "$@"; fi ;;
            *:laravel) php artisan serve --host=0.0.0.0 --port=8000 "$@" ;;
            *)         run "$@" ;;
        esac
    )

}
