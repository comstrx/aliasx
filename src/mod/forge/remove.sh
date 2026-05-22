
del () {

    (
        local kind=""

        [[ $# -gt 0 ]] || { err "Missing package name"; return; }

        cdroot || return
        kind="$(lang)" || return

        case "${kind}" in
            php:laravel)

                composer remove "$@"

            ;;
            php:php)

                composer remove "$@"

            ;;
            python:uv)

                uv remove "$@"

            ;;
            python:python)

                local py=""

                py="$(python-bin)" || return

                "${py}" -m pip uninstall -y "$@" || return

                [[ -f requirements.txt ]] && { "${py}" -m pip freeze > requirements.txt; }

            ;;
            rust:cargo)

                cargo remove "$@"

            ;;
            go:go)

                local pkg=""

                for pkg in "$@"; do
                    go get "${pkg}@none" || return
                done

                go mod tidy

            ;;
            zig:zig)

                err "Remove packages manually in build.zig.zon"

            ;;
            cpp:xmake)

                local pkg="" tmp=""

                [[ -f xmake.lua ]] || { err "Missing xmake.lua"; return; }

                for pkg in "$@"; do

                    tmp="$(mktemp)" || return

                    awk -v pkg="${pkg}" \
                        -v req="add_requires(\"${pkg}\")" \
                        -v pkgs="add_packages(\"${pkg}\")" '
                        index($0, req)  > 0 { next }
                        index($0, pkgs) > 0 { next }
                        { print }
                    ' xmake.lua > "${tmp}" \
                    && mv "${tmp}" xmake.lua

                done

            ;;
            cmake:cmake)

                err "Unsupported dependency remove for CMake project"

            ;;
            dotnet:dotnet)

                local pkg=""

                for pkg in "$@"; do
                    dotnet remove package "${pkg}" || return
                done

            ;;
            mojo:pixi)

                pixi remove "$@"

            ;;
            mojo:mojo)

                err "Unsupported dependency remove for Mojo project without Pixi"

            ;;
            dart:dart)

                dart pub remove "$@"

            ;;
            dart:flutter)

                flutter pub remove "$@"

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
            sh:bash)

                local file=""

                if   [[ -f del.sh ]]; then bash del.sh "$@"
                elif [[ -f remove.sh ]]; then bash remove.sh "$@"
                elif [[ -f uninstall.sh ]]; then bash uninstall.sh "$@"
                elif [[ -f src/remove.sh ]]; then bash src/remove.sh "$@"
                elif [[ -f src/uninstall.sh ]]; then bash src/uninstall.sh "$@"
                elif file="$(entry sh)"; then bash "${file}" remove "$@"
                else err "Unable to detect remove semantic for the project."
                fi

            ;;
            lua:lua)

                luarocks remove "$@"

            ;;
            *)

                err "Unsupported project type"

            ;;
        esac

    )

}
