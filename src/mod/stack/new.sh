new () {

    (
        local input="${1:-}" name="${2:-}" type="" variant="" project="" cleanup="" rc=0

        [[ -n "${input}" ]] || { err "Missing project type"; return; }
        [[ -n "${name}"  ]] || { err "Missing project name"; return; }

        IFS=: read -r type variant <<<"${input}"
        type="${type,,}"
        variant="${variant,,}"

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
                    gradle|app*) type="gradle"; variant="" ;;
                    lib|library) type="gradle"; variant="lib" ;;
                    maven)       type="maven";  variant="" ;;
                    *)           err "Unsupported java variant: ${variant}"; return ;;
                esac
            ;;
        esac

        if [[ "${name}" == "." ]]; then

            project="$(basename "$(pwd -P)")"

        else

            [[ "${name}" =~ ^[A-Za-z0-9_][A-Za-z0-9_.-]*$ ]] || { err "Invalid project name: ${name}"; return; }
            [[ ! -e "${name}" ]] || { err "Path already exists: ${name}"; return; }

            mkdir -p -- "${name}" || return
            cd      -- "${name}" || { rmdir -- "../${name}" 2>/dev/null; return; }

            cleanup="$(pwd -P)"
            project="${name}"

        fi

        trap '
            rc=$?
            if [[ -n "${cleanup}" && "${cleanup}" != / && "${cleanup}" != "${HOME}" ]]; then
                cd "$(dirname "${cleanup}")" 2>/dev/null && rm -rf -- "${cleanup}" 2>/dev/null
            fi
            return "${rc}"
        ' ERR

        case "${type}" in

            bash)
                _new-hello bash "${project}"
                chmod +x main.sh
            ;;

            lua)
                _new-hello lua "${project}"
            ;;

            python)
                local py="" args=( "${@:3}" )

                case "${variant}" in
                    nogil|free|freethreaded|t) py="${PYTHON_NOGIL_VERSION:-3.13t}" ;;
                esac

                [[ -n "${py}" ]] && {
                    uv python install "${py}" >/dev/null 2>&1 || { err "Failed to install Python ${py}"; return; }
                    args=( --python "${py}" "${args[@]}" )
                }

                uv init --quiet . "${args[@]}" 2>/dev/null || uv init . "${args[@]}" || { err "uv init failed"; return; }
            ;;

            python-pure)
                local py="python3"

                [[ "${variant}" =~ ^(gil|nogil|free|t)$ ]] && {
                    [[ -x /opt/python-3.14t/bin/python3.14 ]] || { err "Python 3.14t not found"; return; }
                    py="/opt/python-3.14t/bin/python3.14"
                }

                "${py}" -m venv .venv || { err "venv creation failed"; return; }

                _new-hello python "${project}"
                : > requirements.txt
            ;;

            php)
                local vendor="${3:-vendor/${project}}"

                composer init --no-interaction --name "${vendor}" "${@:4}" 2>/dev/null \
                    || { err "composer init failed"; return; }

                _new-hello php "${project}"
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
                _new-hello go "${project}"
            ;;

            zig)
                zig init >/dev/null 2>&1 || { err "zig init failed"; return; }
            ;;

            mojo)
                command -v pixi >/dev/null 2>&1 || { err "pixi not installed"; return; }

                pixi init --quiet . -c https://conda.modular.com/max-nightly/ -c conda-forge >/dev/null 2>&1 \
                    || pixi init    . -c https://conda.modular.com/max-nightly/ -c conda-forge \
                    || { err "pixi init failed"; return; }

                pixi add mojo --quiet >/dev/null 2>&1 || pixi add mojo || { err "pixi add mojo failed"; return; }
                _new-hello mojo "${project}"
            ;;

            xmake)
                xmake create -f -P . -l "${variant:-c++}" -t console "${project}" >/dev/null 2>&1 \
                    || { err "xmake create failed"; return; }
            ;;

            cmake)
                local std="11" lang="C" ext="c" inc="stdio.h" stmt="printf( \"Hello from ${project}\\n\" );"

                [[ "${variant}" != "c" ]] && {
                    std="17"; lang="CXX"; ext="cpp"; inc="iostream"
                    stmt="std::cout << \"Hello from ${project}\\n\";"
                }

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
                command -v dart >/dev/null 2>&1 || { err "dart not installed"; return; }

                case "${variant}" in
                    lib|package) dart create --quiet --template package . "${@:3}" ;;
                    cli)         dart create --quiet --template cli-simple . "${@:3}" ;;
                    *)           dart create --quiet --template console . "${@:3}" ;;
                esac || { err "dart create failed"; return; }
            ;;

            flutter)
                command -v flutter >/dev/null 2>&1 || { err "flutter not installed"; return; }

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

                flutter create "${args[@]}" . "${@:4}" >/dev/null 2>&1 \
                    || { err "flutter create failed"; return; }
            ;;

            bun)
                bun init -y >/dev/null 2>&1 || { err "bun init failed"; return; }
            ;;

            node)
                local pm="${variant:-npm}"

                case "${pm}" in
                    bun)  bun  init -y           >/dev/null 2>&1 || { err "bun init failed";  return; } ;;
                    pnpm) pnpm init              >/dev/null 2>&1 || { err "pnpm init failed"; return; }; _new-hello node "${project}" ;;
                    yarn) yarn init -y           >/dev/null 2>&1 || { err "yarn init failed"; return; }
                          yarn install --silent  >/dev/null 2>&1 || { err "yarn install failed"; return; }; _new-hello node "${project}" ;;
                    npm)  npm  init -y           >/dev/null 2>&1 || { err "npm init failed";  return; }; _new-hello node "${project}" ;;
                    node|pure) _new-hello node "${project}" ;;
                    *) err "Unsupported node package manager: ${pm}"; return ;;
                esac
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

                "${cmd[@]}" . --yes --typescript --tailwind --eslint --app --src-dir --no-import-alias --no-turbopack \
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
                local groupId="${3:-com.example}"
                [[ "${name}" == "." ]] && { err "maven requires a named project (cannot use '.')"; return; }

                cd .. || return
                rmdir -- "${project}" 2>/dev/null

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

        trap - ERR
        cleanup=""

        _new-common "${project}" "${type}"
        _new-git

        succ "Created ${type}${variant:+:${variant}} → ${project}"

    )

}

_write () {

    local file="${1:-}"
    [[ -n "${file}" ]] || return

    if [[ "${file}" == */* ]]; then
        mkdir -p -- "$(dirname -- "${file}")" || return
    fi

    sed 's/^\t//' > "${file}"

}
_new-hello () {

    local kind="${1:-}" project="${2:-project}"

    case "${kind}" in

        bash)
            _write main.sh <<-EOF
			#!/usr/bin/env bash
			set -Eeuo pipefail

			main () {

			    echo "Hello from ${project}"

			}

			main "\$@"
			EOF
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
            _write main.py <<-EOF

			def main () -> None:

			    print( "Hello from ${project}" )


			if __name__ == "__main__":
			    main()
			EOF
        ;;

        php)
            _write main.php <<-EOF
			<?php

			declare( strict_types = 1 );

			echo "Hello from ${project}" . PHP_EOL;
			EOF
        ;;

        go)
            _write main.go <<-EOF
			package main

			import "fmt"

			func main () {

			    fmt.Println( "Hello from ${project}" )

			}
			EOF
        ;;

        mojo)
            _write main.mojo <<-EOF
			def main():
			    print( "Hello from ${project}" )
			EOF
        ;;

        node)
            _write index.js <<-EOF
			console.log( "Hello from ${project}" );
			EOF
        ;;

    esac

}
_new-common () {

    local project="${1:-project}" type="${2:-Polyglot}"

    [[ -f .gitignore ]] || _write .gitignore <<-'EOF'
	.idea/
	.vscode/
	.vs/
	*.swp
	*.swo

	.DS_Store
	Thumbs.db
	*:Zone.Identifier

	build/
	dist/
	out/
	target/
	zig-out/

	.cache/
	.turbo/
	.parcel-cache/
	.pytest_cache/
	.mypy_cache/
	.ruff_cache/
	.zig-cache/
	__pycache__/

	node_modules/
	.venv/
	venv/
	vendor/

	*.log
	*.tmp
	.env*
	!.env.example
	.secrets*
	!.secrets.example
	EOF

    [[ -f .editorconfig ]] || _write .editorconfig <<-'EOF'
	root = true

	[*]
	indent_style = space
	indent_size = 4
	end_of_line = lf
	charset = utf-8
	trim_trailing_whitespace = true
	insert_final_newline = true

	[*.{yml,yaml,json,md,toml}]
	indent_size = 2

	[Makefile]
	indent_style = tab
	EOF

    [[ -f .gitattributes ]] || _write .gitattributes <<-'EOF'
	* text=auto eol=lf
	*.sh text eol=lf
	*.bat text eol=crlf
	*.{png,jpg,jpeg,gif,ico,pdf,zip,gz,xz} binary
	EOF

    [[ -f README.md ]] || _write README.md <<-EOF
	# ${project}

	_${type} project_

	\`\`\`
	\`\`\`
	EOF

}
_new-git () {

    [[ -d .git ]] && return 0
    command -v git >/dev/null 2>&1 || return 0

    git init -q --initial-branch=main 2>/dev/null || git init -q
    git add -A 2>/dev/null

    git -c user.email=- -c user.name=- commit -q -m 'chore: initial commit' 2>/dev/null

    return 0

}
