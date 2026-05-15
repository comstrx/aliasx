
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

            [[ -f .env      ]] || printf 'APP_NAME=%s\n' "${project}" > .env
            [[ -f .secrets  ]] || printf 'APP_NAME=%s\n' "${project}" > .secrets
            [[ -f README.md ]] || printf '# %s\n\n_%s project_\n\n```\n```\n' "${project}" "${type}" > README.md

        }

        local input="${1:-}" name="${2:-}" type="" variant="" project="" cleanup="" failed=1

        [[ -n "${input}" ]] || { err "Missing project type"; return; }
        [[ -n "${name}"  ]] || { err "Missing project name"; return; }

        trap '
            if (( failed )) && [[ -n "${cleanup}" && "${cleanup}" != / && "${cleanup}" != "${HOME}" ]]; then
                cd "$(dirname "${cleanup}")" 2>/dev/null && rm -rf -- "${cleanup}" 2>/dev/null
            fi
        ' EXIT

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
            sh|shell)          type="bash" ;;
            luarocks)          type="lua" ;;
            cargo)             type="rust" ;;
            c#|csharp)         type="dotnet" ;;
            c)                 type="cmake"; variant="c" ;;
            cpp|c++|hpp)       type="cmake"; variant="${variant:-cpp}" ;;
            npm|pnpm|yarn)     variant="${type}"; type="node" ;;
            rn|expo)           type="react-native" ;;
            uv|py|py3|python3) type="python" ;;
            py*-pure|pure-py*) type="python-pure" ;;
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

                local py="" args=( "${@:3}" )

                case "${variant}" in
                    nogil|free|freethreaded|t) py="3.14t" ;;
                    gil|standard)              py="3.14"  ;;
                    3.*)                       py="${variant}" ;;
                esac

                if [[ -n "${py}" ]]; then
                    uv python install "${py}" >/dev/null 2>&1 || { err "Failed to install Python ${py}"; return; }
                    args=( --python "${py}" "${args[@]}" )
                fi

                uv init --quiet . "${args[@]}" 2>/dev/null || uv init . "${args[@]}" || { err "uv init failed"; return; }

            ;;
            python-pure)

                local py="python3"

                if [[ "${variant}" =~ ^(gil|nogil|free|t)$ ]]; then

                    [[ -x /opt/python-3.14t/bin/python3.14 ]] || { err "Python 3.14t not found"; return; }
                    py="/opt/python-3.14t/bin/python3.14"

                fi

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

                local vendor="${3:-vendor/${project}}"

                composer init --no-interaction --name "${vendor}" "${@:4}" 2>/dev/null \
                    || { err "composer init failed"; return; }

                _write main.php <<-EOF
				<?php

				declare( strict_types = 1 );

				echo "Hello from ${project}" . PHP_EOL;
				EOF

            ;;
            laravel)

                composer create-project --quiet laravel/laravel . "${@:3}" 2>/dev/null \
                    || { err "laravel install failed"; return; }

            ;;
            rust)

                case "${variant}" in
                    lib) cargo init --quiet --lib . ;;
                    *)   cargo init --quiet . ;;
                esac || { err "cargo init failed"; return; }

            ;;
            go)

                local module="${3:-${project}}"

                go mod init "${module}" >/dev/null 2>&1 || { err "go mod init failed"; return; }

                _write main.go <<-EOF
				package main

				import "fmt"

				func main () {

				    fmt.Println( "Hello from ${project}" )

				}
				EOF

            ;;
            zig)

                zig init >/dev/null 2>&1 || { err "zig init failed"; return; }

            ;;
            mojo)

                pixi init --quiet . -c https://conda.modular.com/max-nightly/ -c conda-forge >/dev/null 2>&1 \
                    || pixi init    . -c https://conda.modular.com/max-nightly/ -c conda-forge \
                    || { err "pixi init failed"; return; }

                pixi add mojo --quiet >/dev/null 2>&1 || pixi add mojo || { err "pixi add mojo failed"; return; }

                _write main.mojo <<-EOF
				def main():
				    print( "Hello from ${project}" )
				EOF

            ;;
            xmake)

                xmake create -f -P . -l "${variant:-c++}" -t console "${project}" >/dev/null 2>&1 \
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

                case "${variant}" in
                    lib|package) dart create --quiet --template package . "${@:3}" ;;
                    cli)         dart create --quiet --template cli-simple . "${@:3}" ;;
                    *)           dart create --quiet --template console . "${@:3}" ;;
                esac || { err "dart create failed"; return; }

            ;;
            flutter)

                local org="${3:-com.example}" app=""
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

                flutter create "${args[@]}" . "${@:4}" >/dev/null 2>&1 || { err "flutter create failed"; return; }

            ;;
            bun)

                bun init -y >/dev/null 2>&1 || { err "bun init failed"; return; }

            ;;
            node)

                local pm="${variant:-npm}"

                case "${pm}" in
                    node|pure) ;;
                    bun)  bun  init -y           >/dev/null 2>&1 || { err "bun init failed";  return; } ;;
                    pnpm) pnpm init              >/dev/null 2>&1 || { err "pnpm init failed"; return; } ;;
                    npm)  npm  init -y           >/dev/null 2>&1 || { err "npm init failed";  return; } ;;
                    yarn) yarn init -y           >/dev/null 2>&1 || { err "yarn init failed"; return; }
                          yarn install --silent  >/dev/null 2>&1 || { err "yarn install failed"; return; } ;;
                    *)    err "Unsupported node package manager: ${pm}"; return ;;
                esac

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
                    npm)  cmd=( npx --yes create-vite@latest ) ;;
                    *) err "Unsupported react package manager: ${pm}"; return ;;
                esac

                "${cmd[@]}" . --template react-ts --no-interactive >/dev/null 2>&1 \
                    || { err "react scaffold failed"; return; }

                "${pm}" install --silent >/dev/null 2>&1 || true

            ;;
            react-native)

                local pm="${variant:-npm}"
                local -a cmd=()

                case "${pm}" in
                    bun)  cmd=( bun x create-expo-app@latest ) ;;
                    pnpm) cmd=( pnpm dlx create-expo-app@latest ) ;;
                    yarn) cmd=( yarn dlx create-expo-app@latest ) ;;
                    npm)  cmd=( npx --yes create-expo-app@latest ) ;;
                    *) err "Unsupported react-native package manager: ${pm}"; return ;;
                esac

                "${cmd[@]}" . --yes >/dev/null 2>&1 || { err "expo scaffold failed"; return; }

            ;;
            next)

                local pm="${variant:-npm}"
                local -a cmd=()

                case "${pm}" in
                    bun)  cmd=( bun  create next-app@latest ) ;;
                    pnpm) cmd=( pnpm create next-app@latest ) ;;
                    yarn) cmd=( yarn create next-app ) ;;
                    npm)  cmd=( npx --yes create-next-app@latest ) ;;
                    *) err "Unsupported next package manager: ${pm}"; return ;;
                esac

                "${cmd[@]}" . --yes \
                    --typescript --tailwind --eslint \
                    --app --src-dir --no-import-alias --no-turbopack \
                    >/dev/null 2>&1 || { err "next scaffold failed"; return; }

            ;;
            astro)

                local pm="${variant:-npm}"
                local -a cmd=()

                case "${pm}" in
                    bun)  cmd=( bunx create-astro@latest ) ;;
                    pnpm) cmd=( pnpm dlx create-astro@latest ) ;;
                    yarn) cmd=( yarn create astro ) ;;
                    npm)  cmd=( npm  create astro@latest -- ) ;;
                    *) err "Unsupported astro package manager: ${pm}"; return ;;
                esac

                "${cmd[@]}" . --template minimal --install --no-git --skip-houston --yes \
                    >/dev/null 2>&1 || { err "astro scaffold failed"; return; }

            ;;
            dotnet)

                local tpl="${variant:-console}"

                case "${tpl}" in
                    api) tpl="webapi"   ;;
                    lib) tpl="classlib" ;;
                esac

                dotnet new "${tpl}" --name "${project}" --output . --force >/dev/null 2>&1 \
                    || { err "dotnet new ${tpl} failed"; return; }

            ;;
            maven)

                local groupId="${3:-com.example}" parent=""
                [[ "${name}" == "." ]] && { err "maven requires a named project"; return; }

                parent="$(dirname -- "${cleanup}")"

                cd "${parent}" || return
                rm -rf -- "${project}" 2>/dev/null
                cleanup=""

                mvn -q archetype:generate \
                    -DgroupId="${groupId}" \
                    -DartifactId="${project}" \
                    -DarchetypeArtifactId=maven-archetype-quickstart \
                    -DinteractiveMode=false 2>/dev/null \
                    || { err "maven archetype failed"; rm -rf -- "${project}" 2>/dev/null; return; }

                cd -- "${project}" || return
                cleanup="$(pwd -P)"

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
                    --quiet \
                    2>/dev/null || { err "gradle init failed"; return; }

            ;;
            *)

                err "Unsupported project type: ${type}"
                return

            ;;

        esac

        _new-common "${project}" "${type}"
        _new-git

        failed=0
        succ "Created ${type}${variant:+:${variant}} → ${project}"

    )

}
