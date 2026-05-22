#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2119,SC2120
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd -P)"

BUILD_DIR="${BUILD_DIR:-target}"
SOURCE_DIR="${SOURCE_DIR:-src}"
TEST_DIR="${TEST_DIR:-tests}"

TARGET_NAME="${TARGET_NAME:-dev}"
BINARY_NAME="${BINARY_NAME:-}"
BINARY_FILE="${BINARY_FILE:-}"

MODULES=( core mod )

declare -A META=( [version]="0.1.2" [name]="aliasx" [bin]="ax" )

colored () {

    [[ -z "${NO_COLOR:-}" ]] || return 1
    [[ -n "${FORCE_COLOR:-}" || -n "${GITHUB_ACTIONS:-}" ]] && return 0
    [[ -n "${TERM:-}" ]] || return 1
    [[ "${TERM:-}" != "dumb" ]] || return 1
    [[ -t 1 || -t 2 ]]

}
out () {

    printf '%b\n' "$*"
    return 0

}
log () {

    printf '%b\n' "$*" >&2
    return 0

}
info () {

    if colored; then printf '\033[96m[*]\033[0m %b\n' "$*" >&2
    else printf '[*] %b\n' "$*" >&2
    fi

    return 0

}
succ () {

    if colored; then printf '\033[32m[+]\033[0m %b\n' "$*" >&2
    else printf '[+] %b\n' "$*" >&2
    fi

    return 0

}
warn () {

    if colored; then printf '\033[33m[!]\033[0m %b\n' "$*" >&2
    else printf '[!] %b\n' "$*" >&2
    fi

    return 0

}
err () {

    if colored; then printf '\033[31m[-]\033[0m %b\n' "$*" >&2
    else printf '[-] %b\n' "$*" >&2
    fi

    return 1

}
err_tmp () {

    local tmp="${1:-}"
    shift >/dev/null 2>&1 || true

    [[ -n "${tmp}" ]] && { rm -f -- "${tmp}" 2>/dev/null || true; }
    (( $# > 0 )) && err "$@"

    return 1

}
bool () {

    local name="${1:-}" n=""
    shift >/dev/null 2>&1 || true

    case "${name,,}" in
        1|t|true|y|yes|on) return 0 ;;
    esac

    for n in "$@"; do

        [[ -n "${n}" ]] || continue
        case "${name,,}" in "${n,,}"|"-${n,,}"|"--${n,,}") return 0 ;;  esac

    done

    return 1

}
confirm () {

    local default="${1:-no}" msg="${2:-Are you sure}" answer="" hint=""

    [[ "${msg}" == *\? ]] || msg="${msg}?"

    case "${default,,}" in
        1|t|true|y|yes|on) hint="[Y/n]"; default="yes" ;;
        *)                 hint="[y/N]"; default="no"  ;;
    esac

    [[ ! -t 0 ]] && { [[ "${default}" == "yes" ]]; return; }

    read -r -p "${msg} ${hint} " answer

    case "${answer,,}" in
        "")                [[ "${default}" == "yes" ]] ;;
        1|t|true|y|yes|on) return 0 ;;
        *)                 return 1 ;;
    esac

}

load_source () {

    local src="${1:-}" file=""

    [[ "${src}" == /* ]] || src="${ROOT_DIR}/${src#/}"

    if [[ -f "${src}" ]]; then

        cat -- "${src}" || { err "Failed to read source file: ${src}"; return; }
        printf '\n'
        return

    fi
    if [[ -f "${src}.sh" ]]; then

        cat -- "${src}.sh" || { err "Failed to read source file: ${src}.sh"; return; }
        printf '\n'
        return

    fi
    if [[ -d "${src}" ]]; then

        while IFS= read -r -d '' file; do

            cat -- "${file}" || { err "Failed to read source file: ${file}"; return; }
            printf '\n'

        done < <(find "${src}" \( -type d -name '_*' -prune \) -o \( -type f -name '*.*sh' ! -name '_*' -print0 \) | sort -z)

        return

    fi

    err "Source not found: ${src}"
    return

}
build_source () {

    local mod=""

    for mod in "${MODULES[@]}"; do
        load_source "${SOURCE_DIR}/${mod}" || return
    done

    if [[ "${TARGET_NAME}" == "dev" && -e "${TEST_DIR}" ]]; then
        load_source "${TEST_DIR}" || return
    fi

}
build_header () {

    printf '%s\n' "#!/usr/bin/env bash"
    printf '%s\n' "# shellcheck disable=SC1090,SC1091,SC2016,SC2317,SC2119,SC2120"

}
build_entry () {

	cat <<-'EOF'
	runner () {

		set -Eeuo pipefail

		local raw="${1:-}" word="" cand="" fn="" seen=" "

		[[ -n "${raw}" ]] || return 0
		shift >/dev/null 2>&1 || true

		for word in "${raw}" "${raw,,}" "${raw^^}" "${raw^}"; do

			for cand in "${word}" "${word//-/_}" "${word//_/-}" "${word//-/}" "${word//_/}"; do

				[[ -n "${cand}" ]] || continue
				[[ " ${seen} " == *" ${cand} "* ]] && continue

				seen="${seen}${cand} "
				declare -F "${cand}" >/dev/null 2>&1 || continue

				fn="${cand}"
				break 2

			done

		done

		[[ -n "${fn}" ]] || { err "Unknown command: ${raw}"; return; }
		"${fn}" "$@"

	}

	if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then runner "$@"; fi
	EOF

}
builder () {

    local bin="${BINARY_FILE}" tmp="" temp=""

    temp="$(dirname -- "${bin}")/.${bin##*/}.tmp.XXXXXX"
    tmp="$(mktemp "${temp}")" || { err "Failed to create temp file: ${temp}"; return; }

    {

        build_header || return
        build_source || return
        build_entry  || return

    } > "${tmp}" || { err_tmp "${tmp}" "Failed to build bundle: ${bin}"; return; }

    bash -n "${tmp}" || return

    mv -f -- "${tmp}" "${bin}" || { err_tmp "${tmp}" "Failed to build bundle: ${bin}"; return; }
    chmod +x -- "${bin}"       || { err_tmp "${tmp}" "Failed to chmod bundle: ${bin}"; return; }

}

local_bin_dir () {

    local dir="${HOME}/.local/bin"

    mkdir -p -- "${dir}" || { err "Failed to create bin directory: ${dir}"; return; }
    out "${dir}"

}
local_rc_file () {

    local shell="${SHELL##*/}" file=""

    case "${shell}" in
        zsh)  file="${HOME}/.zshrc" ;;
        bash) file="${HOME}/.bashrc" ;;
        *)    file="${HOME}/.profile" ;;
    esac

    touch -- "${file}" || { err "Failed to create rc file: ${file}"; return; }
    out "${file}"

}
install_bin () {

    local src="${1:-}" name="${2:-}" dir="" out=""

    [[ -f "${src}" ]] || { err "Missing bundle file"; return; }

    name="${name:-${src##*/}}"
    name="${name##*/}"
    name="${name%.*}"

    dir="$(local_bin_dir)" || return
    out="${dir}/${name}"

    [[ ! -e "${out}" ]] || confirm true "Overwrite existing ${out}" || return

    cp -- "${src}" "${out}" || { err "Failed to install bin: ${out}"; return; }
    chmod +x -- "${out}" || { err "Failed to chmod bin: ${out}"; return; }

    out "${out}"

}
install_rc () {

    local src="${1:-}" rc="" line=""

    [[ -f "${src}" ]] || { err "Missing installed file: ${src}"; return; }

    rc="$(local_rc_file)" || return
    line="if [[ -f \"${src}\" ]]; then source \"${src}\"; fi"

    if ! grep -Fxq -- "${line}" "${rc}"; then

        { printf '\n%s\n%s\n' "# ${src##*/}" "${line}"; } >> "${rc}" \
            || { err "Failed to update rc file: ${rc}"; return; }

    fi

}
installer () {

    local name="${1:-${BINARY_NAME}}" profile="${2:-1}" src="${BINARY_FILE}" rc=0 bin="" append=0

    bool "${profile}" profile source p s && append=1

    (( rc == 0 )) && { bin="$(install_bin "${src}" "${name}")" || rc=$?; }
    (( rc == 0 && append == 1 )) && { install_rc "${bin}" || rc=$?; }

    (( rc == 0 )) || return "${rc}"

    succ "Installed -> ${bin}"
    info "Run: source ${bin}"

}

match_tests () {

    local src="${1:-}" line="" probe="" fn="" mark=0 skip=0

    while IFS= read -r line || [[ -n "${line}" ]]; do

        line="${line%$'\r'}"
        probe="${line}"
        probe="${probe//[[:space:]]/}"
        probe="${probe,,}"

        if [[ "${probe}" =~ ^#@?(\[(no-test|no_test)\]|no-test|no_test)$ ]]; then
            mark=0; skip=1
            continue
        fi
        if [[ "${probe}" =~ ^#@?(\[test\]|test)$ ]]; then
            mark=1; skip=0
            continue
        fi
        if [[ "${line}" =~ ^[[:space:]]*(function[[:space:]]+)?([A-Za-z_][A-Za-z0-9_-]*)[[:space:]]*(\(\))?[[:space:]]*\{ ]]; then

            fn="${BASH_REMATCH[2]}"
            if (( ! skip )) && { (( mark )) || [[ "${fn}" == test_* ]]; }; then out "${fn}"; fi

            mark=0; skip=0
            continue

        fi

        [[ "${line}" =~ ^[[:space:]]*$ ]] && continue
        mark=0; skip=0

    done < "${src}" | sort -u || { err "Failed matching tests"; return; }

}
find_tests () {

    local src="${1:-}" fn="" out=""

    out="$(match_tests "${src}")" || return

    while IFS= read -r fn; do
        [[ -n "${fn}" ]] && { out "${fn}"; }
    done <<< "${out}"

}
tester () {

    local src="${BINARY_FILE}" fn="" out="" result="" required="" check=0 rc=0 found=0 pass=0 fail=0 total=0
    local -a tests=() args=()

    for arg in "$@"; do
        case "${arg,,}" in
            --check|-c) check=1 ;;
            *)
                if [[ -z "${required}" ]]; then required="${arg}"
                else args+=( "${arg}" )
                fi
            ;;
        esac
    done

    (( check )) && { checker || return; }

    out="$(find_tests "${src}")" || return
    mapfile -t tests <<< "${out}"

    for fn in "${tests[@]}"; do

        [[ -n "${fn}" ]] || continue
        [[ -z "${required}" || "${required}" == "${fn}" ]] || continue
        [[ -n "${required}" ]] && found=1

        total=$(( total + 1 ))

        if result="$("${src}" "${fn}" "${args[@]}" 2>&1)"; then

            pass=$(( pass + 1 ))
            succ "${fn} Passed ✓"

        else

            fail=$(( fail + 1 )); rc=1
            err "${fn} Failed ✗"
            [[ -n "${result}" ]] && log "    ${result}"

        fi

        [[ -n "${required}" ]] && break

    done

    if [[ -n "${required}" && "${found}" -eq 0 ]]; then
        rc=1; fail=1; total=1
        err "Test not found: ${required}"
    fi

    if (( rc == 0 )); then succ "Pass: ${pass}, Fail: ${fail}, Total: ${total}"
    else err "Pass: ${pass}, Fail: ${fail}, Total: ${total}"
    fi

    return "${rc}"

}

checker () {

    local src="${BINARY_FILE}"

    bash -n "${src}" || return
    shellcheck -s bash -x -e SC1090,SC1091,SC2016,SC2317,SC2119,SC2120 "${src}" || return

    succ "Check passed"

}
runner () {

    local src="${BINARY_FILE}"
    "${src}" "$@"

}
releaser () {

    local src="${BINARY_FILE}"

    if ! bash -c 'source "${1}"; declare -F release >/dev/null 2>&1' bash "${src}"; then
        out "version=${META[version]}\nname=${META[name]}\nbin=${BINARY_FILE}"
        return 0
    fi

    "${src}" release "${META[version]}" "${META[name]}" "${BINARY_FILE}" --sync --backup "$@"

}

prepare () {

    local dir="${1:-}" target="${2:-}" name="${3:-}" bin=""

    [[ -n "${dir}"    ]] || dir="${BUILD_DIR}"
    [[ -n "${target}" ]] || target="${TARGET_NAME}"
    [[ -n "${name}"   ]] || name="${BINARY_NAME:-${META[bin]}}"

    target="${target#--}"
    target="${target#-}"
    name="${name##*/}"

    [[ "${target,,}" == r* ]] && target="release" || target="dev"
    [[ "${name}" == *.*sh ]] || name="${name}.sh"

    bin="${ROOT_DIR}/${dir}/${target}/${name}"
    mkdir -p -- "$(dirname -- "${bin}")" || { err "Failed to create out dir: ${bin}"; return; }

    BUILD_DIR="${dir}"
    TARGET_NAME="${target}"
    BINARY_NAME="${name}"
    BINARY_FILE="${bin}"

}
main () {

    local cmd="${1:-}"

    shift >/dev/null 2>&1 || true

    case "${cmd,,}" in
        install|build-release|release) TARGET_NAME="release" ;;
    esac

    prepare || return
    builder || return

    case "${cmd,,}" in
        build)         succ "Built -> ${BINARY_FILE}" ;;
        build-release) succ "Built -> ${BINARY_FILE}" ;;
        release)       releaser  "$@" || return ;;
        install)       installer "$@" || return ;;
        check)         checker   "$@" || return ;;
        test)          tester    "$@" || return ;;
        run)           runner    "$@" || return ;;
        name)          out "${META[name]}" ;;
        bin)           out "${META[bin]}" ;;
        version)       out "${META[version]}" ;;
        tag)           out "v${META[version]}" ;;
        *)             runner "${cmd}" "$@" || return ;;
    esac

}

main "$@"
