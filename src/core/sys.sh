
has () {

    [[ -n "${1:-}" ]] || { err "Missing binary name"; return; }

    command -v "${1}" >/dev/null 2>&1

}
need () {

    has "${1:-}" || { err "Missing: ${1:-}"; return; }

}
has-all () {

    local bin="" fail=0

    for bin in "$@"; do
        has "${bin}" || fail=1
    done

    (( fail == 0 ))

}
need-all () {

    local bin="" fail=0

    for bin in "$@"; do
        has "${bin}" || { err "Missing: ${bin}"; fail=1; }
    done

    (( fail == 0 ))

}

is-linux () {

    local s=""

    has uname && s="$(uname -s 2>/dev/null || true)"

    [[ "${s}" == "Linux" ]] && return 0
    [[ "${OSTYPE:-}" == linux* ]]

}
is-macos () {

    local s=""

    has uname && s="$(uname -s 2>/dev/null || true)"

    [[ "${s}" == "Darwin" ]] && return 0
    [[ "${OSTYPE:-}" == darwin* ]]

}
is-wsl () {

    local r=""

    is-linux || return 1
    [[ -n "${WSL_DISTRO_NAME:-}" || -n "${WSL_INTEROP:-}" ]] && return 0

    if [[ -r /proc/sys/kernel/osrelease ]]; then

        IFS= read -r r < /proc/sys/kernel/osrelease || true

        r="$(lower "${r}")"
        [[ "${r}" == *microsoft* ]] && return 0

    fi
    if [[ -r /proc/version ]]; then

        IFS= read -r r < /proc/version || true

        r="$(lower "${r}")"
        [[ "${r}" == *microsoft* ]] && return 0

    fi

    return 1

}

is-cygwin () {

    local s=""

    [[ "${OSTYPE:-}" == cygwin* ]] && return 0
    has uname && { s="$(uname -s 2>/dev/null || true)"; [[ "${s}" == CYGWIN* ]]; }

}
is-msys () {

    local s=""

    [[ "${OSTYPE:-}" == msys* ]] && return 0

    if has uname; then
        s="$(uname -s 2>/dev/null || true)"
        [[ "${s}" == MSYS* || "${s}" == MINGW* ]] && return 0
    fi

    case "${MSYSTEM:-}" in
        MSYS|MINGW*|UCRT*|CLANG*) return 0 ;;
    esac

    return 1

}
is-gitbash () {

    is-msys || return 1

    [[ -n "${GitInstallRoot:-}" ]] && return 0
    [[ "${OSTYPE:-}" == msys* && "${MSYSTEM:-}" == MINGW* && -n "${WINDIR:-}" ]] && return 0

    [[ "${TERM_PROGRAM:-}" == "mintty" && "${MSYSTEM:-}" == MINGW* && -z "${MSYS2_PATH_TYPE:-}" ]]

}
is-windows () {

    is-wsl    && return 1
    is-msys   && return 0
    is-cygwin && return 0

    [[ "${OSTYPE:-}" == win32* || "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* ]] && return 0
    [[ -n "${WINDIR:-}" || -n "${SystemRoot:-}" || -n "${COMSPEC:-}" ]] || return 1

    is-linux && return 1
    is-macos && return 1

    return 0

}
is-unix () {

    is-linux || is-macos

}
is-posix () {

    is-linux || is-macos || is-wsl || is-msys || is-cygwin

}

ci-name () {

    [[ -n "${GITHUB_ACTIONS:-}" ]]         && { out github;    return; }
    [[ -n "${GITLAB_CI:-}" ]]              && { out gitlab;    return; }
    [[ -n "${JENKINS_URL:-}" ]]            && { out jenkins;   return; }
    [[ -n "${BUILDKITE:-}" ]]              && { out buildkite; return; }
    [[ -n "${CIRCLECI:-}" ]]               && { out circleci;  return; }
    [[ -n "${TRAVIS:-}" ]]                 && { out travis;    return; }
    [[ -n "${APPVEYOR:-}" ]]               && { out appveyor;  return; }
    [[ -n "${TF_BUILD:-}" ]]               && { out azure;     return; }
    [[ -n "${BITBUCKET_BUILD_NUMBER:-}" ]] && { out bitbucket; return; }
    [[ -n "${TEAMCITY_VERSION:-}" ]]       && { out teamcity;  return; }
    [[ -n "${DRONE:-}" ]]                  && { out drone;     return; }
    [[ -n "${SEMAPHORE:-}" ]]              && { out semaphore; return; }
    [[ -n "${CODEBUILD_BUILD_ID:-}" ]]     && { out codebuild; return; }
    [[ -n "${CI:-}" ]]                     && { out generic;   return; }

    out none
    return 1

}
is-ci () {

    ci-name >/dev/null 2>&1

}
is-ci-pull () {

    [[ "${GITHUB_EVENT_NAME:-}" == "pull_request" || "${GITHUB_EVENT_NAME:-}" == "pull_request_target" ]] && return 0
    [[ -n "${CI_MERGE_REQUEST_IID:-}" ]] && return 0
    [[ -n "${BITBUCKET_PR_ID:-}" ]] && return 0
    [[ -n "${SYSTEM_PULLREQUEST_PULLREQUESTID:-}" ]] && return 0

    [[ "${BUILD_REASON:-}" == "PullRequest" ]]

}
is-ci-push () {

    is-ci || return 1
    is-ci-pull && return 1

    [[ "${GITHUB_EVENT_NAME:-}" == "push" ]] && return 0
    [[ "${CI_PIPELINE_SOURCE:-}" == "push" ]] && return 0
    [[ -n "${BITBUCKET_COMMIT:-}" && -z "${BITBUCKET_PR_ID:-}" ]] && return 0

    [[ "${BUILD_REASON:-}" == "IndividualCI" || "${BUILD_REASON:-}" == "BatchedCI" ]]

}
is-ci-tag () {

    [[ "${GITHUB_REF_TYPE:-}" == "tag" ]] && return 0
    [[ -n "${CI_COMMIT_TAG:-}" ]] && return 0
    [[ -n "${BITBUCKET_TAG:-}" ]] && return 0

    [[ "${BUILD_SOURCEBRANCH:-}" == refs/tags/* ]]

}

is-terminal () {

    [[ -t 0 || -t 1 || -t 2 ]]

}
is-interactive () {

    [[ "${-}" == *i* ]]

}
is-gui () {

    if is-linux; then

        [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]
        return

    fi
    if is-macos; then

        [[ -z "${SSH_CONNECTION:-}" && -z "${SSH_CLIENT:-}" && -z "${SSH_TTY:-}" && -z "${CI:-}" ]]
        return

    fi
    if is-windows; then

        is-ci && return 1

        [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_CLIENT:-}" || -n "${SSH_TTY:-}" ]] && return 1
        [[ -n "${WINDIR:-}" || -n "${SystemRoot:-}" ]]

        return

    fi

    return 1

}
is-headless () {

    is-gui && return 1
    return 0

}
is-container () {

    local r=""

    [[ -f /.dockerenv || -f /run/.containerenv ]] && return 0

    if [[ -r /run/systemd/container ]]; then

        IFS= read -r r < /run/systemd/container || true
        [[ -n "${r}" ]] && return 0

    fi
    if [[ -r /proc/1/cgroup ]]; then

        while IFS= read -r r || [[ -n "${r}" ]]; do

            r="$(lower "${r}")"

            case "${r}" in
                *docker*|*kubepods*|*containerd*|*podman*|*lxc*) return 0 ;;
            esac

        done < /proc/1/cgroup

    fi
    if [[ -r /proc/1/environ ]]; then

        while IFS= read -r -d '' r; do
            [[ "${r}" == container=* ]] && return 0
        done < /proc/1/environ

    fi

    return 1

}

is-root () {

    local v=""

    is-windows && has net.exe && net.exe session >/dev/null 2>&1 && return 0
    has id || return 1

    v="$(id -u 2>/dev/null || true)"
    [[ "${v}" == "0" ]]

}

os () {

    if is-linux;   then out linux;   return; fi
    if is-macos;   then out macos;   return; fi
    if is-windows; then out windows; return; fi

    err unknown
    return

}
runtime () {

    if is-wsl;     then out wsl;     return; fi
    if is-gitbash; then out gitbash; return; fi
    if is-msys;    then out msys2;   return; fi
    if is-cygwin;  then out cygwin;  return; fi
    if is-linux;   then out linux;   return; fi
    if is-macos;   then out macos;   return; fi
    if is-windows; then out windows; return; fi

    err unknown
    return

}
kernel () {

    local v=""

    if has uname; then

        v="$(uname -s 2>/dev/null || true)"
        [[ -n "${v}" ]] && { out "${v}"; return; }

    fi
    if is-windows; then

        out Windows
        return

    fi

    err unknown
    return

}
distro () {

    local id="" line="" file="" rt=""

    if is-linux; then

        for file in /etc/os-release /usr/lib/os-release; do

            [[ -r "${file}" ]] || continue

            while IFS= read -r line || [[ -n "${line}" ]]; do

                [[ "${line}" == ID=* ]] || continue

                id="${line#*=}"
                id="${id%\"}"
                id="${id#\"}"

                [[ -n "${id}" ]] && { out "${id}"; return; }

            done < "${file}"

        done

        out linux
        return

    fi
    if is-macos; then

        out macos
        return

    fi
    if is-windows; then

        rt="$(runtime 2>/dev/null || true)"
        [[ -n "${rt}" && "${rt}" != "unknown" ]] && { out "${rt}"; return; }

        out windows
        return

    fi

    err unknown
    return

}
manager () {

    if is-linux; then

        has apt-get      && { out apt;    return; }
        has apk          && { out apk;    return; }
        has dnf          && { out dnf;    return; }
        has yum          && { out yum;    return; }
        has pacman       && { out pacman; return; }
        has zypper       && { out zypper; return; }
        has xbps-install && { out xbps;   return; }
        has brew         && { out brew;   return; }
        has nix          && { out nix;    return; }

        err unknown
        return

    fi
    if is-macos; then

        has brew && { out brew; return; }
        has port && { out port; return; }
        has nix  && { out nix;  return; }

        err unknown
        return

    fi
    if is-windows; then

        is-msys && has pacman && { out pacman; return; }

        has winget && { out winget; return; }
        has scoop  && { out scoop;  return; }
        has choco  && { out choco;  return; }
        has pacman && { out pacman; return; }

        err unknown
        return

    fi

    err unknown
    return

}

run-cmd () {

    (( $# > 0 )) || return 0
    "$@"

}
run-sudo () {

    (( $# > 0 )) || return 0
    is-root && { "$@"; return; }

    if has sudo; then

        sudo -n true >/dev/null 2>&1 && { sudo -n "$@"; return; }
        sudo "$@"
        return

    fi

    "$@"

}
run-ok () {

    run-cmd "$@" >/dev/null 2>&1

}
run-sudo-ok () {

    run-sudo "$@" >/dev/null 2>&1

}
