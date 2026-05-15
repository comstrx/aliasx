
add () {

    (
        local kind=""

        [[ $# -gt 0 ]] || { err "Missing package name"; return; }

        cdroot || return
        kind="$(lang)" || return

        case "${kind}" in
            php:laravel)

                composer require "$@"

            ;;
            php:php)

                composer require "$@"

            ;;
            python:uv)

                uv add "$@"

            ;;
            python:python)

                local py=""
                py="$(python-bin)" || return

                "${py}" -m pip install "$@" || return
                [[ -f requirements.txt ]] && { "${py}" -m pip freeze > requirements.txt; }

            ;;
            rust:cargo)

                cargo add "$@"

            ;;
            go:go)

                go get "$@" && go mod tidy

            ;;
            zig:zig)

                zig fetch --save "$@"

            ;;
            cpp:xmake)

                local pkg="" tmp=""

                [[ -f xmake.lua ]] || { err "Missing xmake.lua"; return; }

                for pkg in "$@"; do

                    if ! grep -qE "^[[:space:]]*add_requires\([\"']${pkg}[\"']" xmake.lua; then

                        tmp="$(mktemp)" || return

                        awk -v pkg="${pkg}" '
                            BEGIN { inserted = 0 }
                            !inserted && /^target\(/ {
                                print "add_requires(\"" pkg "\")"
                                print ""
                                inserted = 1
                            }
                            { print }
                            END {
                                if ( !inserted ) {
                                    print ""
                                    print "add_requires(\"" pkg "\")"
                                }
                            }
                        ' xmake.lua > "${tmp}" && mv "${tmp}" xmake.lua

                    fi

                    tmp="$(mktemp)" || return

                    awk -v pkg="${pkg}" -v needle="add_packages(\"${pkg}\")" '
                        BEGIN { in_target = 0; has_pkg = 0 }
                        /^target\(/ {
                            if ( in_target && !has_pkg ) print "    add_packages(\"" pkg "\")"
                            in_target = 1; has_pkg = 0
                            print
                            next
                        }
                        in_target && index($0, needle) > 0 { has_pkg = 1 }
                        /^[^[:space:]]/ && !/^target\(/ {
                            if ( in_target && !has_pkg ) {
                                print "    add_packages(\"" pkg "\")"
                                has_pkg = 1
                            }
                            in_target = 0
                        }
                        { print }
                        END {
                            if ( in_target && !has_pkg ) print "    add_packages(\"" pkg "\")"
                        }
                    ' xmake.lua > "${tmp}" && mv "${tmp}" xmake.lua

                    xmake require -y "${pkg}" || return

                done

            ;;
            cmake:cmake)

                err "Unsupported dependency add for CMake project"

            ;;
            dotnet:dotnet)

                local pkg=""

                for pkg in "$@"; do
                    dotnet add package "${pkg}" || return
                done

            ;;
            mojo:pixi)

                pixi add "$@"

            ;;
            mojo:mojo)

                err "Unsupported dependency add for Mojo project without Pixi"

            ;;
            dart:dart)

                dart pub add "$@"

            ;;
            dart:flutter)

                flutter pub add "$@"

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
            sh:bash)

                err "Unsupported dependency install for shell project"

            ;;
            lua:lua)

                luarocks install "$@"

            ;;
            *)

                err "Unsupported project type"

            ;;
        esac

    )

}
