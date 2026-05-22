
tools () {

    if declare -p EMPIRE_TOOLS >/dev/null 2>&1; then printf '%s\n' "${EMPIRE_TOOLS[@]}"
    elif declare -p TOOLS >/dev/null 2>&1; then printf '%s\n' "${TOOLS[@]}"
    fi

}
tool-info () {

    local bin="${1:-}" package="${2:-}" version="${3:-}" delim=":" spec="" b="" p="" v=""

    [[ -n "${bin}" ]] || { err "Missing binary name"; return; }

    [[ "${bin}" == *","* ]] && delim=","
    [[ "${bin}" == *"|"* ]] && delim="|"

    IFS="${delim}" read -r bin package version <<< "${bin}"

    while IFS= read -r spec || [[ -n "${spec}" ]]; do

        [[ -n "${spec}" ]] || continue

        IFS=: read -r b p v <<< "${spec}"

        [[ "${b}" == "${bin}" ]] || continue

        [[ -n "${package}" ]] || package="${p:-${b}}"
        [[ -n "${version}" ]] || version="${v:-}"

        break

    done < <(tools)

    printf '%s:%s:%s\n' "${bin}" "${package:-${bin}}" "${version}"

}

refresh-sys () {

    local manager=""
    manager="$(manager)" || return

    case "${manager}" in
        apt)    run-sudo apt-get update -qq ;;
        apk)    run-sudo apk update ;;
        dnf)    run-sudo dnf makecache -y ;;
        yum)    run-sudo yum makecache -y ;;
        zypper) run-sudo zypper --non-interactive refresh ;;
        xbps)   run-sudo xbps-install -S ;;
        pacman) run-sudo pacman -Sy --noconfirm ;;
        brew)   run-cmd brew update ;;
        port)   run-cmd port selfupdate ;;
        winget) run-cmd winget source update ;;
        scoop)  run-cmd scoop update ;;
        *)      return 0 ;;
    esac

}
install-bin () {

    local bin="" package="" version="" manager=""

    IFS=: read -r bin package version < <(tool-info "$@")
    [[ -n "${bin}" ]] || { err "bin name required"; return; }

    manager="$(manager)" || return

    case "${manager}" in
        apt)
            if [[ -n "${version}" ]]; then run-sudo apt-get install -y "${package}=${version}"
            else run-sudo apt-get install -y "${package}"
            fi
        ;;
        apk)
            if [[ -n "${version}" ]]; then run-sudo apk add "${package}=${version}"
            else run-sudo apk add "${package}"
            fi
        ;;
        dnf)
            if [[ -n "${version}" ]]; then run-sudo dnf install -y "${package}-${version}"
            else run-sudo dnf install -y "${package}"
            fi
        ;;
        yum)
            if [[ -n "${version}" ]]; then run-sudo yum install -y "${package}-${version}"
            else run-sudo yum install -y "${package}"
            fi
        ;;
        zypper)
            if [[ -n "${version}" ]]; then run-sudo zypper --non-interactive install "${package}=${version}"
            else run-sudo zypper --non-interactive install "${package}"
            fi
        ;;
        xbps)
            if [[ -n "${version}" ]]; then run-sudo xbps-install -Sy "${package}-${version}"
            else run-sudo xbps-install -Sy "${package}"
            fi
        ;;
        nix)
            if [[ -n "${version}" ]]; then run-cmd nix profile install "nixpkgs/${version}#${package}"
            else run-cmd nix profile install "nixpkgs#${package}"
            fi
        ;;
        brew)
            if [[ -n "${version}" ]]; then run-cmd brew install "${package}@${version}"
            else run-cmd brew install "${package}"
            fi
        ;;
        port)
            [[ -n "${version}" ]] && return 1
            run-cmd port install "${package}"
        ;;
        pacman)
            if [[ -n "${version}" ]]; then return 1
            else run-sudo pacman -S --needed --noconfirm --noprogressbar "${package}"
            fi
        ;;
        winget)
            if [[ -n "${version}" ]]; then
                run-cmd "${manager}" install -e \
                    --id "${package}" \
                    --version "${version}" --source winget \
                    --accept-package-agreements \
                    --accept-source-agreements \
                    --disable-interactivity
            else
                run-cmd "${manager}" install -e \
                    --id "${package}" --source winget \
                    --accept-package-agreements \
                    --accept-source-agreements \
                    --disable-interactivity
            fi
        ;;
        scoop)
            if [[ -n "${version}" ]]; then run-cmd "${manager}" install "${package}@${version}"
            else run-cmd "${manager}" install "${package}"
            fi
        ;;
        choco)
            if [[ -n "${version}" ]]; then run-cmd "${manager}" install -y "${package}" "--version=${version}"
            else run-cmd "${manager}" install -y "${package}"
            fi
        ;;
        *)
            err "Unknown manager to install"
            return
        ;;
    esac || return

    return 0

}
remove-bin () {

    local bin="" package="" manager=""

    IFS=: read -r bin package < <(tool-info "$@")
    [[ -n "${bin}" ]] || { err "bin name required"; return; }

    manager="$(manager)" || return

    case "${manager}" in
        apt)    run-sudo apt-get remove -y "${package}" ;;
        apk)    run-sudo apk del "${package}" ;;
        dnf)    run-sudo dnf remove -y "${package}" ;;
        yum)    run-sudo yum remove -y "${package}" ;;
        zypper) run-sudo zypper --non-interactive remove "${package}" ;;
        xbps)   run-sudo xbps-remove -Ry "${package}" ;;
        pacman) run-sudo pacman -R --noconfirm "${package}" ;;
        nix)    run-cmd nix profile remove "${package}" ;;
        brew)   run-cmd brew uninstall "${package}" ;;
        port)   run-cmd port uninstall "${package}" ;;
        winget) run-cmd winget uninstall -e --id "${package}" --source winget --disable-interactivity ;;
        scoop)  run-cmd scoop uninstall "${package}" ;;
        choco)  run-cmd choco uninstall -y "${package}" ;;
        *)      err "Unknown manager to remove"; return ;;
    esac || return

    return 0

}

ensure () {

    local bin="" package="" version=""

    IFS=: read -r bin package version < <(tool-info "$@")
    [[ -n "${bin}" ]] || { err "bin name required"; return; }

    has "${bin}" && return 0

    install-bin "${bin}" "${package}" "${version}" \
        || { err "Failed to install bin: ${bin}"; return; }

    has "${bin}" || { err "Failed to detect bin: ${bin}"; return; }

}
ensure-ok () {

    ensure "$@" >/dev/null 2>&1

}

install-all () {

    local spec="" fail=0

    refresh-sys 2>/dev/null || true

    for spec in "$@"; do
        install-bin "${spec}" || fail=1
    done

    (( fail == 0 ))

}
remove-all () {

    local spec="" fail=0

    refresh-sys 2>/dev/null || true

    for spec in "$@"; do
        remove-bin "${spec}" || fail=1
    done

    (( fail == 0 ))

}
ensure-all () {

    local spec="" fail=0

    refresh-sys 2>/dev/null || true

    for spec in "$@"; do
        ensure "${spec}" || fail=1
    done

    (( fail == 0 ))

}

empire () {

    declare -p EMPIRE_TOOLS >/dev/null 2>&1 || { err "Missing EMPIRE_TOOLS array"; return; }
    (( ${#EMPIRE_TOOLS[@]} > 0 )) || { err "EMPIRE_TOOLS array is empty"; return; }

    ensure-all "${EMPIRE_TOOLS[@]}" || { err "Empire incomplete"; return; }
    succ "Empire ready"

}
doctor () {

    local spec="" bin="" package="" version="" ok=0 missing=0 total=0

    declare -p EMPIRE_TOOLS >/dev/null 2>&1 || { err "Missing EMPIRE_TOOLS array"; return; }

    while IFS= read -r spec || [[ -n "${spec}" ]]; do

        [[ -n "${spec}" ]] || continue

        bin="" package="" version=""
        IFS=: read -r bin package version < <(tool-info "${spec}")

        [[ -n "${bin}" ]] || { warn "Invalid tool: ${spec}"; (( missing++ )); continue; }
        (( total++ ))

        if has "${bin}"; then succ "${bin}"; (( ok++ ))
        else warn "Missing: ${bin} -> ${package:-${bin}}${version:+:${version}}"; (( missing++ ))
        fi

    done < <(tools)

    (( missing == 0 )) && { succ "Empire ready: ${ok}/${total} tools installed"; return 0; }
    err "Empire incomplete: ${missing}/${total} tools missing"

}
