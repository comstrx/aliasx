
new () {

    (
        _write () {

            local file="${1:-}"

            [[ -n "${file}" ]] || return
            [[ "${file}" == */* ]] && { mkdir -p -- "$(dirname -- "${file}")" || return; }

            sed 's/^\t//' > "${file}"

        }
        _new-git () {

            [[ -d .git ]] && return 0

            git init -q --initial-branch=main 2>/dev/null || git init -q
            git add -A 2>/dev/null

            git -c user.email=- -c user.name=- commit -q -m 'chore: initial commit' 2>/dev/null

        }
        _new-common () {

            local project="${1:-project}" type="${2:-Polyglot}"

            [[ -f .gitignore     ]] || gitignores    > .gitignore
            [[ -f .dockerignore  ]] || dockerignores > .dockerignore
            [[ -f .editorconfig  ]] || editorconfigs > .editorconfig
            [[ -f .gitattributes ]] || gitattributes > .gitattributes

            [[ -f .env      ]] || [[ "${type}" == "laravel" ]] || printf 'APP_NAME=%s\n' "${project}" > .env
            [[ -f .secrets  ]] || [[ "${type}" == "laravel" ]] || printf 'APP_NAME=%s\n' "${project}" > .secrets
            [[ -f README.md ]] || printf "# %s\n\n_%s project_\n\n\`\`\`\n\`\`\`\n" "${project}" "${type}" > README.md

        }

        local input="${1:-}" name="${2:-}" type="" variant="" project="" cleanup="" failed=1 config=0 git=0 arg=""
        local -a pass=()

        [[ -n "${input}" ]] || { err "Missing project type"; return; }
        [[ -n "${name}"  ]] || { err "Missing project name"; return; }

        shift 2 >/dev/null 2>&1 || true

        for arg in "$@"; do

            case "${arg,,}" in
                --config)    config=1; git=1 ;;
                --no-config) config=0; git=0 ;;
                --git)       git=1 ;;
                --no-git)    git=0 ;;
                *)           pass+=( "${arg}" ) ;;
            esac

        done

        trap '(( failed )) && [[ -n "${cleanup}" && "${cleanup}" != / && "${cleanup}" != "${HOME}" ]] && rm -rf -- "${cleanup}"' EXIT

        IFS=: read -r type variant <<<"${input}"
        type="${type,,}"
        variant="${variant,,}"

        if [[ "${name}" == "." ]]; then

            project="$(basename "$(pwd -P)")"

        else

            [[ "${name}" =~ ^[A-Za-z0-9_][A-Za-z0-9_.-]*$ ]] || { err "Invalid project name: ${name}"; return; }
            [[ ! -e "${name}" ]] || { err "Path already exists: ${name}"; return; }

            mkdir -p -- "${name}" || return
            cd -- "${name}" || { rm -rf -- "../${name}" 2>/dev/null; return; }

            cleanup="$(pwd -P)"
            project="${name}"

        fi

        case "${type}" in
            sh|shell)              type="bash" ;;
            luarocks)              type="lua" ;;
            cargo)                 type="rust" ;;
            c#|csharp)             type="dotnet" ;;
            c|h)                   type="xmake"; variant="c" ;;
            cpp|c++|hpp)           type="xmake"; variant="c++" ;;
            npm|pnpm|yarn)         variant="${type}"; type="node" ;;
            rn|expo)               type="react-native" ;;
            uv|py|py3|python3)     type="python" ;;
            py-pure|python-pure|pypure) type="python-pure" ;;
            java)
                case "${variant:-gradle}" in
                    lib|library) type="gradle"; variant="lib" ;;
                    gradle|app*) type="gradle"; variant="" ;;
                    maven)       type="maven";  variant="" ;;
                    *)           err "Unsupported java variant: ${variant}"; return ;;
                esac
            ;;
        esac
        case "${type}" in
            bash)

                _write main.sh <<-EOF
				#!/usr/bin/env bash
				set -Eeuo pipefail

				main () {

				    echo "Hello from ${project}"

				}

				main "\$@"
				EOF

                chmod +x main.sh

            ;;
            lua)

                _write main.lua <<-EOF

				local function main ()

				    print( "Hello from ${project}" )

				end

				main()
				EOF

            ;;
            python)

                local py=""
                local -a args=( "${pass[@]}" )

                case "${variant}" in
                    nogil|free|freethreaded|t) py="3.14t" ;;
                    gil|standard)              py="3.14"  ;;
                    3.*)                       py="${variant}" ;;
                esac

                if [[ -n "${py}" ]]; then
                    uv python install "${py}" || { err "Failed to install Python ${py}"; return; }
                    args=( --python "${py}" "${args[@]}" )
                fi

                uv init --quiet . "${args[@]}" || uv init . "${args[@]}" \
                    || { err "uv init failed"; return; }

            ;;
            python-pure)

                local py="python3"

                case "${variant}" in
                    nogil|free|freethreaded|t)
                        if   [[ -x /opt/python-3.14t/bin/python3.14 ]]; then py="/opt/python-3.14t/bin/python3.14"
                        elif command -v python3.14t >/dev/null 2>&1;  then py="python3.14t"
                        else err "Python 3.14t not found"; return
                        fi
                    ;;
                    gil|standard|"") ;;
                    *) err "Unsupported python-pure variant: ${variant}"; return ;;
                esac

                "${py}" -m venv .venv || { err "venv creation failed"; return; }
                : > requirements.txt

                _write main.py <<-EOF

				def main () -> None:

				    print( "Hello from ${project}" )


				if __name__ == "__main__":
				    main()
				EOF

            ;;
            php)

                local vendor="${pass[0]:-vendor/${project}}"

                [[ "${#pass[@]}" -gt 0 ]] && pass=( "${pass[@]:1}" )

                composer init --no-interaction --name "${vendor}" "${pass[@]}" \
                    || { err "composer init failed"; return; }

                _write main.php <<-EOF
				<?php

				declare( strict_types = 1 );

				echo "Hello from ${project}" . PHP_EOL;
				EOF

            ;;
            laravel)

                composer create-project --quiet laravel/laravel . "${pass[@]}" \
                    || { err "laravel install failed"; return; }

            ;;
            rust)

                case "${variant}" in
                    lib) cargo init --quiet --lib . ;;
                    *)   cargo init --quiet . ;;
                esac || { err "cargo init failed"; return; }

            ;;
            go)

                local module="${pass[0]:-${project}}"

                go mod init "${module}" || { err "go mod init failed"; return; }

                _write main.go <<-EOF
				package main

				import "fmt"

				func main () {

				    fmt.Println( "Hello from ${project}" )

				}
				EOF

            ;;
            zig)

                zig init || { err "zig init failed"; return; }

            ;;
            mojo)

                pixi init --quiet . -c https://conda.modular.com/max-nightly/ -c conda-forge \
                    || pixi init    . -c https://conda.modular.com/max-nightly/ -c conda-forge \
                    || { err "pixi init failed"; return; }

                pixi add mojo --quiet || pixi add mojo || { err "pixi add mojo failed"; return; }

                _write main.mojo <<-EOF
				def main():
				    print( "Hello from ${project}" )
				EOF

            ;;
            xmake)

                xmake create -f -P . -l "${variant:-c++}" -t console "${project}" \
                    || { err "xmake create failed"; return; }

            ;;
            cmake)

                local std="11" lang="C" ext="c" inc="stdio.h" stmt="printf( \"Hello from ${project}\\n\" );"

                if [[ "${variant}" != "c" ]]; then
                    std="17"; lang="CXX"; ext="cpp"; inc="iostream"
                    stmt="std::cout << \"Hello from ${project}\\n\";"
                fi

                mkdir -p src

                _write CMakeLists.txt <<-EOF
				cmake_minimum_required( VERSION 3.16 )

				project( ${project} ${lang} )

				set( CMAKE_${lang}_STANDARD ${std} )
				set( CMAKE_${lang}_STANDARD_REQUIRED ON )
				set( CMAKE_${lang}_EXTENSIONS OFF )

				add_executable( ${project} src/main.${ext} )
				EOF

                _write "src/main.${ext}" <<-EOF
				#include <${inc}>

				int main () {

				    ${stmt}
				    return 0;

				}
				EOF

            ;;
            dart)

                local tpl="console"

                case "${variant}" in
                    ""|console)  tpl="console" ;;
                    cli)         tpl="cli" ;;
                    server)      tpl="server-shelf" ;;
                    web)         tpl="web" ;;
                    lib|package) tpl="package" ;;
                    *)           err "Unsupported dart variant: ${variant}"; return ;;
                esac

                dart create --template "${tpl}" --force . "${pass[@]}" \
                    || { err "dart create failed"; return; }

            ;;
            flutter)

                local org="${pass[0]:-com.example}" app=""
                local -a args=()

                app="${project,,}"
                app="${app//-/_}"
                app="${app//./_}"
                app="$(printf '%s' "${app}" | tr -cd 'a-z0-9_')"

                [[ -n "${app}" ]] || app="app"
                [[ "${app}" =~ ^[a-z] ]] || app="app_${app}"

                args=( --quiet --org "${org}" --project-name "${app}" )

                case "${variant}" in
                    plugin|package|module) args+=( --template "${variant}" ) ;;
                esac

                [[ "${#pass[@]}" -gt 0 ]] && pass=( "${pass[@]:1}" )

                flutter create "${args[@]}" . "${pass[@]}" || { err "flutter create failed"; return; }

            ;;
            bun)

                bun init -y || { err "bun init failed"; return; }

            ;;
            node)

                local pm="${variant:-npm}" tmp=""

                case "${pm}" in
                    node|pure) ;;
                    bun)  bun  init -y          || { err "bun init failed";  return; } ;;
                    pnpm) pnpm init             || { err "pnpm init failed"; return; } ;;
                    npm)  npm  init -y          || { err "npm init failed";  return; } ;;
                    yarn) yarn init -y          || { err "yarn init failed"; return; }
                          yarn install --silent || { err "yarn install failed"; return; } ;;
                    *)    err "Unsupported node package manager: ${pm}"; return ;;
                esac

                if [[ "${pm}" != "bun" && -f package.json ]] && command -v jq >/dev/null 2>&1; then

                    tmp="$(mktemp)" || true

                    if [[ -n "${tmp}" ]]; then
                        jq 'if .scripts.test == "echo \"Error: no test specified\" && exit 1" then del(.scripts.test) else . end' \
                            package.json > "${tmp}" 2>/dev/null && mv "${tmp}" package.json
                    fi

                fi
                if [[ "${pm}" != "bun" && ! -f "index.js" && ! -f "index.ts" ]]; then

                    _write index.js <<-EOF
					console.log( "Hello from ${project}" );
					EOF

                fi

            ;;
            react)

                local pm="${variant:-npm}"
                local -a cmd=()

                case "${pm}" in
                    bun)  cmd=( bun  create vite@latest ) ;;
                    pnpm) cmd=( pnpm create vite@latest ) ;;
                    yarn) cmd=( yarn create vite ) ;;
                    npm)  cmd=( npm  create vite@latest -- ) ;;
                    *)    err "Unsupported react package manager: ${pm}"; return ;;
                esac

                "${cmd[@]}" . --template react-ts --no-interactive --no-immediate --overwrite \
                    || { err "react scaffold failed"; return; }

                [[ -d node_modules ]] || "${pm}" install || return

            ;;
            react-native)

                local pm="${variant:-npm}"
                local -a cmd=()

                case "${pm}" in
                    bun)  cmd=( bunx create-expo-app@latest ) ;;
                    pnpm) cmd=( pnpm create expo-app@latest ) ;;
                    yarn) cmd=( yarn create expo-app ) ;;
                    npm)  cmd=( npm  create --yes expo-app@latest -- ) ;;
                    *)    err "Unsupported react-native package manager: ${pm}"; return ;;
                esac

                "${cmd[@]}" . --template blank --yes --no-install \
                    || { err "expo scaffold failed"; return; }

                [[ -d node_modules ]] || "${pm}" install || return

            ;;
            next)

                local pm="${variant:-npm}"
                local -a cmd=()

                case "${pm}" in
                    bun)  cmd=( bun  create next-app@latest ) ;;
                    pnpm) cmd=( pnpm create next-app@latest ) ;;
                    yarn) cmd=( yarn create next-app ) ;;
                    npm)  cmd=( npm  create --yes next-app@latest -- ) ;;
                    *)    err "Unsupported next package manager: ${pm}"; return ;;
                esac

                "${cmd[@]}" . --yes --skip-install --disable-git \
                    --typescript --tailwind --eslint --app --src-dir --no-import-alias --no-turbopack \
                    || { err "next scaffold failed"; return; }

                [[ -d node_modules ]] || "${pm}" install || return

            ;;
            astro)

                local pm="${variant:-npm}"
                local -a cmd=()

                case "${pm}" in
                    bun)  cmd=( bun  create astro@latest ) ;;
                    pnpm) cmd=( pnpm create astro@latest ) ;;
                    yarn) cmd=( yarn create astro ) ;;
                    npm)  cmd=( npm  create --yes astro@latest -- ) ;;
                    *)    err "Unsupported astro package manager: ${pm}"; return ;;
                esac

                NODE_OPTIONS="--dns-result-order=ipv4first ${NODE_OPTIONS:-}" \
                    "${cmd[@]}" . --template minimal --no-install --no-git --skip-houston --yes \
                    || { err "astro scaffold failed"; return; }

                [[ -d node_modules ]] || "${pm}" install || return

            ;;
            vue)

                local pm="${variant:-npm}"
                local -a cmd=()

                case "${pm}" in
                    bun)  cmd=( bun  create vue@latest ) ;;
                    pnpm) cmd=( pnpm create vue@latest ) ;;
                    yarn) cmd=( yarn create vue ) ;;
                    npm)  cmd=( npm  create --yes vue@latest -- ) ;;
                    *)    err "Unsupported vue package manager: ${pm}"; return ;;
                esac

                cd .. || return

                "${cmd[@]}" "${project}" --force --typescript --router --eslint \
                    || { err "vue scaffold failed"; return; }

                cd -- "${project}" || return
                cleanup="$(pwd -P)"

                [[ -d node_modules ]] || "${pm}" install || return

            ;;
            nuxt)

                local pm="${variant:-npm}"
                local -a cmd=()

                case "${pm}" in
                    bun)  cmd=( bunx --bun nuxi@latest init ) ;;
                    pnpm) cmd=( pnpm dlx   nuxi@latest init ) ;;
                    yarn) cmd=( yarn dlx   nuxi@latest init ) ;;
                    npm)  cmd=( npx  --yes nuxi@latest init ) ;;
                    *)    err "Unsupported nuxt package manager: ${pm}"; return ;;
                esac

                NUXT_TELEMETRY_DISABLED=1 "${cmd[@]}" \
                    --template=minimal --packageManager="${pm}" --gitInit=false \
                    --no-install --preferOffline --force . \
                    || { err "nuxt scaffold failed"; return; }

                [[ -d node_modules ]] || NUXT_TELEMETRY_DISABLED=1 "${pm}" install || return

            ;;
            dotnet)

                local tpl="${variant:-console}"

                case "${tpl}" in
                    api) tpl="webapi"   ;;
                    lib) tpl="classlib" ;;
                esac

                dotnet new "${tpl}" --name "${project}" --output . --force \
                    || { err "dotnet new ${tpl} failed"; return; }

            ;;
            maven)

                local groupId="${pass[0]:-com.example}" parent=""

                [[ "${name}" == "." ]] && { err "maven requires a named project"; return; }
                [[ -n "${cleanup}" ]] || { err "maven requires a cleanup context"; return; }

                parent="$(dirname -- "${cleanup}")"

                cd "${parent}" || return
                rm -rf -- "${cleanup}" 2>/dev/null

                mvn -q archetype:generate \
                    -DgroupId="${groupId}" \
                    -DartifactId="${project}" \
                    -DarchetypeArtifactId=maven-archetype-quickstart \
                    -DinteractiveMode=false \
                    || { err "maven archetype failed"; return; }

                cleanup="${parent}/${project}"
                cd -- "${cleanup}" || return

            ;;
            gradle)

                local tpl="java-application"
                [[ "${variant}" == *lib* ]] && tpl="java-library"

                gradle init \
                    --type "${tpl}" \
                    --project-name "${project}" \
                    --dsl kotlin \
                    --test-framework junit-jupiter \
                    --use-defaults \
                    --no-incubating \
                    --quiet || { err "gradle init failed"; return; }

            ;;
            *)

                err "Unsupported project type: ${type}"
                return

            ;;

        esac

        (( config )) && _new-common "${project}" "${type}"
        (( git ))    && _new-git

        # shellcheck disable=SC2034
        failed=0

        succ "Created ${type}${variant:+:${variant}} → ${project}"

    )

}
