
parse_err () {

    printf '\033[31m>> %s\033[0m\n' "$*" >&2
    return 1

}
parse_arg_err () {

    parse_err "Invalid argument ( ${1:-} ): ${2:-}"
    return 1

}
parse_invalid_err () {

    parse_err "Invalid argument ( ${1:-} ): expected ${2:-}"
    return 1

}
parse_return () {

    printf '%s\n' "return 1"
    return 1

}
parse_fail () {

    parse_err "$*"
    parse_return

}

parse_encode () {

    local value="${1-}"

    value="${value//%/%25}"
    value="${value//$'\n'/%0A}"

    printf '%s\n' "${value}"

}
parse_decode () {

    local value="${1-}"

    value="${value//%0A/$'\n'}"
    value="${value//%25/%}"

    printf '%s\n' "${value}"

}
parse_is_flag () {

    [[ "${1-}" == --* || ( "${1-}" == -* && ! "${1-}" =~ ^[-+]?([0-9]+([.][0-9]+)?|[.][0-9]+)$ ) ]]

}
parse_bool_raw () {

    case "${1,,}" in
        1|t|true|y|yes|on)  printf '%s\n' "1"; return 0 ;;
        0|f|false|n|no|off) printf '%s\n' "0"; return 0 ;;
        *)                  return 1 ;;
    esac

}
parse_bool_not () {

    local value=""

    value="$(parse_bool_raw "${1-}")" || return 1
    [[ "${value}" == "1" ]] && printf '%s\n' "0" || printf '%s\n' "1"

}

parse_list_raw () {

    local default="${1-}" i="" ch="" item="" escaped="0"
    local -a vals=()

    [[ -z "${default}" ]] && { printf '__parse_list_count__:0\n'; return 0; }

    for (( i = 0; i < ${#default}; i++ )); do

        ch="${default:i:1}"

        [[ "${escaped}" == "1" ]] && { item+="${ch}"; escaped="0"; continue; }

        case "${ch}" in
            "\\") escaped="1" ;;
            ,)    vals+=( "${item}" ); item="" ;;
            *)    item+="${ch}" ;;
        esac

    done

    [[ "${escaped}" == "1" ]] && item+="\\"

    vals+=( "${item}" )
    printf '__parse_list_count__:%d\n' "${#vals[@]}"

    for item in "${vals[@]}"; do printf 'v:%s\n' "$(parse_encode "${item}")"; done

}
parse_emit_list () {

    local name="${1}" raw="${2}" req="${3:-optional}"
    local line="" count="" encoded="" q=""

    local -a vals=()

    while IFS= read -r line || [[ -n "${line}" ]]; do

        case "${line}" in
            __parse_list_count__:*)
                count="${line#__parse_list_count__:}"
            ;;
            v:*)
                encoded="${line#v:}"
                q="$(parse_decode "${encoded}")" || return 1
                vals+=( "${q}" )
            ;;
        esac

    done <<< "${raw}"

    [[ -z "${count}" || "${count}" =~ ^[0-9]+$ ]] || { parse_arg_err "${name}" "malformed list output"; return 1; }
    [[ -n "${count}" && "${count}" -ne "${#vals[@]}" ]] && { parse_arg_err "${name}" "malformed list output"; return 1; }
    [[ "${req}" == "required" && "${#vals[@]}" -eq 0 ]] && { parse_arg_err "${name}" "at least one value is required"; return 1; }

    printf 'local -a %s=(' "${name}"
    for q in "${vals[@]}"; do printf ' %q' "${q}"; done
    printf ' )\n'

}
parse_emit_default () {

    local name="${1}" type="${2}" default="${3}" raw=""

    if [[ "${type}" == "list" ]]; then

        raw="$(parse_list_raw "${default}")" || return 1
        parse_emit_list "${name}" "${raw}" "optional"
        return $?

    fi

    raw="$(parse_default "${type}" "${default}" "${name}")" || return 1
    raw="$(parse_typing "${type}" "${raw}" "${name}")" || return 1

    printf 'local %s=%q\n' "${name}" "${raw}"

}

parse_validate () {

    case "${1:-}" in
        bool|str|char|int|uint|float|num|list) return 0 ;;
        path|dir|file|link|exec|mode|ext)      return 0 ;;
        date|time|datetime)                    return 0 ;;
        port|ip|host|domain)                   return 0 ;;
        url|email|phone|semver)                return 0 ;;
        *)                                     return 1 ;;
    esac

}
parse_typing () {

    local type="${1:-str}" value="${2:-}" name="${3:-value}"

    case "${type}" in
        str)
            printf '%s\n' "${value}"
        ;;
        char)
            [[ "${#value}" -eq 1 ]] || { parse_invalid_err "${name}" "char"; return 1; }
            printf '%s\n' "${value}"
        ;;
        int)
            [[ "${value}" =~ ^[-+]?[0-9]+$ ]] || { parse_invalid_err "${name}" "int"; return 1; }
            printf '%s\n' "${value}"
        ;;
        uint)
            [[ "${value}" =~ ^[0-9]+$ ]] || { parse_invalid_err "${name}" "uint"; return 1; }
            printf '%s\n' "${value}"
        ;;
        float|num)
            [[ "${value}" =~ ^[-+]?([0-9]+([.][0-9]+)?|[.][0-9]+)$ ]] || { parse_invalid_err "${name}" "number"; return 1; }
            printf '%s\n' "${value}"
        ;;
        bool)
            parse_bool_raw "${value}" || { parse_invalid_err "${name}" "bool"; return 1; }
        ;;

        path)
            [[ -e "${value}" ]] || { parse_arg_err "${name}" "path does not exist: ${value}"; return 1; }
            printf '%s\n' "${value}"
        ;;
        dir)
            [[ -d "${value}" ]] || { parse_arg_err "${name}" "directory does not exist: ${value}"; return 1; }
            printf '%s\n' "${value}"
        ;;
        file)
            [[ -f "${value}" ]] || { parse_arg_err "${name}" "file does not exist: ${value}"; return 1; }
            printf '%s\n' "${value}"
        ;;
        link)
            [[ -L "${value}" ]] || { parse_arg_err "${name}" "symbolic link does not exist: ${value}"; return 1; }
            printf '%s\n' "${value}"
        ;;
        exec)
            [[ -x "${value}" ]] || { parse_arg_err "${name}" "executable does not exist: ${value}"; return 1; }
            printf '%s\n' "${value}"
        ;;
        mode)
            [[ "${value}" =~ ^[0-7]{3,4}$ ]] || { parse_invalid_err "${name}" "chmod mode"; return 1; }
            printf '%s\n' "${value}"
        ;;
        ext)
            value="${value##*/}"
            value="${value//\*/}"
            value="${value//[[:space:]]/}"

            while [[ "${value}" == .* ]]; do value="${value#.}"; done
            while [[ "${value}" == *. ]]; do value="${value%.}"; done
            while [[ "${value}" == *..* ]]; do value="${value//../.}"; done

            [[ -n "${value}" ]] || { printf '%s\n' ""; return 0; }
            [[ "${value}" =~ ^[A-Za-z0-9]+([.][A-Za-z0-9]+)*$ ]] || { parse_invalid_err "${name}" "extension"; return 1; }

            printf '.%s\n' "${value}"
        ;;

        date)
            local check=""

            [[ "${value}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || {
                parse_invalid_err "${name}" "date YYYY-MM-DD"
                return 1
            }

            if check="$(date -d "${value}" '+%Y-%m-%d' 2>/dev/null)"; then
                [[ "${check}" == "${value}" ]] || { parse_invalid_err "${name}" "calendar date"; return 1; }
            elif check="$(date -j -f '%Y-%m-%d' "${value}" '+%Y-%m-%d' 2>/dev/null)"; then
                [[ "${check}" == "${value}" ]] || { parse_invalid_err "${name}" "calendar date"; return 1; }
            else
                parse_invalid_err "${name}" "date"; return 1
            fi

            printf '%s\n' "${value}"
        ;;
        time)
            [[ "${value}" =~ ^([01][0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$ ]] || {
                parse_invalid_err "${name}" "time HH:MM or HH:MM:SS"
                return 1
            }

            printf '%s\n' "${value}"
        ;;
        datetime)
            local date_part="" time_part="" zone_part=""

            [[ "${value}" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})[T\ ]([0-9]{2}:[0-9]{2}(:[0-9]{2})?)([Zz]|[-+][0-9]{2}:[0-9]{2})?$ ]] || {
                parse_invalid_err "${name}" "datetime"
                return 1
            }

            date_part="${BASH_REMATCH[1]}"
            time_part="${BASH_REMATCH[2]}"
            zone_part="${BASH_REMATCH[4]:-}"

            parse_typing "date" "${date_part}" "${name}" >/dev/null || return 1
            parse_typing "time" "${time_part}" "${name}" >/dev/null || return 1

            if [[ -n "${zone_part}" && "${zone_part}" != "Z" && "${zone_part}" != "z" ]]; then

                [[ "${zone_part}" =~ ^[-+](0[0-9]|1[0-4]):[0-5][0-9]$ ]] || {
                    parse_invalid_err "${name}" "timezone offset"
                    return 1
                }
                [[ "${zone_part}" != "+14:01" && "${zone_part}" != "+14:02" && "${zone_part}" != "+14:03" && "${zone_part}" != "+14:04" && "${zone_part}" != "+14:05" && "${zone_part}" != "+14:06" && "${zone_part}" != "+14:07" && "${zone_part}" != "+14:08" && "${zone_part}" != "+14:09" ]] || {
                    parse_invalid_err "${name}" "timezone offset"
                    return 1
                }
                [[ "${zone_part}" != "-14:01" && "${zone_part}" != "-14:02" && "${zone_part}" != "-14:03" && "${zone_part}" != "-14:04" && "${zone_part}" != "-14:05" && "${zone_part}" != "-14:06" && "${zone_part}" != "-14:07" && "${zone_part}" != "-14:08" && "${zone_part}" != "-14:09" ]] || {
                    parse_invalid_err "${name}" "timezone offset"
                    return 1
                }

            fi

            printf '%s\n' "${value}"
        ;;

        url)
            [[ "${value}" =~ ^https?://[A-Za-z0-9.-]+(:[0-9]{1,5})?([/?#][^[:space:]]*)?$ ]] || {
                parse_invalid_err "${name}" "url"
                return 1
            }

            printf '%s\n' "${value}"
        ;;
        email)
            [[ "${value}" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+[.][A-Za-z]{2,63}$ ]] || {
                parse_invalid_err "${name}" "email"
                return 1
            }
            [[ "${value}" != *..* ]] || {
                parse_invalid_err "${name}" "email"
                return 1
            }

            printf '%s\n' "${value}"
        ;;
        phone)
            value="${value//[[:space:]().-]/}"

            [[ "${value}" =~ ^[+]?[0-9]{7,15}$ ]] || {
                parse_invalid_err "${name}" "phone"
                return 1
            }

            printf '%s\n' "${value}"
        ;;
        semver)
            [[ "${value}" =~ ^v?(0|[1-9][0-9]*)[.](0|[1-9][0-9]*)[.](0|[1-9][0-9]*)(-[0-9A-Za-z]+([.-][0-9A-Za-z]+)*)?([+][0-9A-Za-z]+([.-][0-9A-Za-z]+)*)?$ ]] || {
                parse_invalid_err "${name}" "semver"
                return 1
            }

            [[ "${value}" == v* ]] && value="${value#v}"
            printf '%s\n' "${value}"
        ;;

        port)
            [[ "${value}" =~ ^[0-9]+$ ]] || { parse_invalid_err "${name}" "port"; return 1; }
            (( value >= 1 && value <= 65535 )) || { parse_arg_err "${name}" "port out of range 1..65535"; return 1; }

            printf '%s\n' "${value}"
        ;;
        ip)
            if [[ "${value}" =~ ^([0-9]{1,3}[.]){3}[0-9]{1,3}$ ]]; then

                local a="" b="" c="" d=""
                IFS='.' read -r a b c d <<< "${value}"

                [[ "${a}" -le 255 && "${b}" -le 255 && "${c}" -le 255 && "${d}" -le 255 ]] || {
                    parse_invalid_err "${name}" "ip"
                    return 1
                }

                printf '%s\n' "${value}"
                return 0

            fi

            [[ "${value}" == *:* ]] || { parse_invalid_err "${name}" "ip"; return 1; }
            [[ "${value}" =~ ^[0-9A-Fa-f:]+$ ]] || { parse_invalid_err "${name}" "ip"; return 1; }
            [[ "${value}" != *:::* && "${value}" != ":" ]] || { parse_invalid_err "${name}" "ip"; return 1; }

            local part="" empty_count="0" part_count="0"
            IFS=':' read -ra parts <<< "${value}"

            for part in "${parts[@]}"; do

                [[ -n "${part}" ]] || { (( empty_count++ )); continue; }
                [[ "${#part}" -le 4 ]] || { parse_invalid_err "${name}" "ip"; return 1; }

                (( part_count++ ))

            done

            if [[ "${value}" == *::* ]]; then
                (( empty_count >= 1 && part_count <= 7 )) || { parse_invalid_err "${name}" "ip"; return 1; }
            else
                (( part_count == 8 )) || { parse_invalid_err "${name}" "ip"; return 1; }
            fi

            printf '%s\n' "${value}"
        ;;
        host)
            if [[ "${value}" =~ ^([0-9]{1,3}[.]){3}[0-9]{1,3}$ ]]; then

                local a="" b="" c="" d=""
                IFS='.' read -r a b c d <<< "${value}"

                [[ "${a}" -le 255 && "${b}" -le 255 && "${c}" -le 255 && "${d}" -le 255 ]] || {
                    parse_invalid_err "${name}" "host"
                    return 1
                }

                printf '%s\n' "${value}"
                return 0

            fi
            if [[ "${value}" == *:* ]]; then

                [[ "${value}" =~ ^[0-9A-Fa-f:]+$ ]] || { parse_invalid_err "${name}" "host"; return 1; }
                [[ "${value}" != *:::* && "${value}" != ":" ]] || { parse_invalid_err "${name}" "host"; return 1; }

                local part="" empty_count="0" part_count="0"
                IFS=':' read -ra parts <<< "${value}"

                for part in "${parts[@]}"; do

                    [[ -n "${part}" ]] || { (( empty_count++ )); continue; }
                    [[ "${#part}" -le 4 ]] || { parse_invalid_err "${name}" "host"; return 1; }

                    (( part_count++ ))

                done

                if [[ "${value}" == *::* ]]; then
                    (( empty_count >= 1 && part_count <= 7 )) || { parse_invalid_err "${name}" "host"; return 1; }
                else
                    (( part_count == 8 )) || { parse_invalid_err "${name}" "host"; return 1; }
                fi

                printf '%s\n' "${value}"
                return 0

            fi
            if (( ${#value} > 253 )); then

                parse_arg_err "${name}" "host too long"
                return 1

            fi
            if [[  ! "${value}" =~ ^([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?[.])*[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$ ]]; then

                parse_invalid_err "${name}" "host"
                return 1

            fi

            printf '%s\n' "${value}"
        ;;
        domain)
            if (( ${#value} > 253 )); then
                parse_arg_err "${name}" "domain too long"
                return 1
            fi
            if [[ ! "${value}" == *.* ]]; then
                parse_invalid_err "${name}" "domain"
                return 1
            fi
            if [[ ! "${value}" =~ ^([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?[.])+[A-Za-z]{2,63}$ ]]; then
                parse_invalid_err "${name}" "domain"
                return 1
            fi

            printf '%s\n' "${value}"
        ;;

        *)
            parse_arg_err "${name}" "unknown type ${type}"
            return 1
        ;;
    esac

}
parse_default () {

    local type="${1:-str}" value="${2:-}" name="${3:-value}"

    case "${type}:${value}" in
        date:now)
            date '+%Y-%m-%d'
        ;;
        time:now)
            date '+%H:%M:%S'
        ;;
        datetime:now)
            date '+%Y-%m-%dT%H:%M:%S%z' | sed -E 's/([+-][0-9]{2})([0-9]{2})$/\1:\2/'
        ;;
        ip:local)
            local ip=""
            ip="$(hostname -I 2>/dev/null | awk '{print $1}')" || true

            [[ -z "${ip}" ]] && { ip="$(ip route get 1.1.1.1 2>/dev/null | awk '/src/ { for (i=1;i<=NF;i++) if ($i=="src") print $(i+1); exit }')" || true; }
            [[ -z "${ip}" ]] && { ip="$(ifconfig 2>/dev/null | awk '/inet / && $2 != "127.0.0.1" { print $2; exit }')" || true; }
            [[ -n "${ip}" ]] || { parse_arg_err "${name}" "failed to detect local ip"; return 1; }

            printf '%s\n' "${ip}"
        ;;
        host:local)
            local host=""
            host="$(hostname 2>/dev/null)" || true

            [[ -n "${host}" ]] || { parse_arg_err "${name}" "failed to detect local host"; return 1; }

            printf '%s\n' "${host}"
        ;;
        domain:local)
            local domain=""
            domain="$(hostname -f 2>/dev/null)" || true

            [[ -z "${domain}" || "${domain}" != *.* ]] && { domain="$(dnsdomainname 2>/dev/null)" || true; }
            [[ -n "${domain}" && "${domain}" == *.* ]] || { parse_arg_err "${name}" "failed to detect local domain"; return 1; }

            printf '%s\n' "${domain}"
        ;;
        *)
            printf '%s\n' "${value}"
        ;;
    esac

}
parse_get () {

    local index="" name="" flag="" short="" type="" required=""
    local arg="" next="" value="" found="0" sep="-1" i=""

    local -a all=() args=() spec=() values=()
    all=( "$@" )

    for i in "${!all[@]}"; do [[ "${all[i]}" == "--" ]] && sep="${i}"; done
    [[ "${sep}" -ge 0 ]] || { parse_err "Missing parser separator: --"; return 1; }

    args=( "${all[@]:0:sep}" )
    spec=( "${all[@]:sep + 1}" )

    [[ "${#spec[@]}" -eq 5 ]] || { parse_err "Invalid get spec: expected index name short type required"; return 1; }

    index="${spec[0]}"
    name="${spec[1]}"
    short="${spec[2]}"
    type="${spec[3]}"
    required="${spec[4]}"
    flag="${name//_/-}"

    [[ "${index}" =~ ^[0-9]+$ ]] || { parse_err "Invalid ${name:-argument}: index must be unsigned integer"; return 1; }
    [[ "${name}" =~ ^[A-Za-z_][A-Za-z0-9_-]*$ ]] || { parse_err "Invalid argument name: ${name}"; return 1; }

    parse_validate "${type}" || { parse_arg_err "${name}" "unknown type ${type}"; return 1; }

    case "${short}" in
        ""|_|-) short="" ;;
        *) [[ "${short}" =~ ^[A-Za-z_][A-Za-z0-9_-]*$ ]] || { parse_arg_err "${name}" "short name ${short}"; return 1; } ;;
    esac
    case "${required}" in
        1|true|yes|req*) required="1" ;;
        0|false|no|opt*) required="0" ;;
        *) parse_arg_err "${name}" "required must be required or optional"; return 1 ;;
    esac

    set -- "${args[@]}"

    while (( $# > 0 )); do

        arg="${1}" next="${2:-}"

        case "${arg}" in
            "--no-${name}="*|"-no-${name}="*|"--no-${flag}="*|"-no-${flag}="*)

                [[ "${type}" == "bool" ]] || { parse_err "Invalid --no-${name}: ${name} is not bool"; return 1; }

                value="$(parse_bool_not "${arg#*=}")" || { parse_err "Invalid --no-${name}: expected bool"; return 1; }
                found="1"

                shift
                continue

            ;;
            "--no-${name}"|"-no-${name}"|"--no-${flag}"|"-no-${flag}")

                [[ "${type}" == "bool" ]] || { parse_err "Invalid --no-${name}: ${name} is not bool"; return 1; }

                if (( $# > 1 )) && parse_bool_raw "${next}" >/dev/null 2>&1; then
                    value="$(parse_bool_not "${next}")" || return 1
                    shift
                else
                    value="0"
                fi

                found="1"

                shift
                continue

            ;;
            "--${name}"|"-${name}"|"--${flag}"|"-${flag}")

                if [[ "${type}" == "bool" ]]; then

                    if (( $# > 1 )) && ! parse_is_flag "${next}"; then
                        value="$(parse_bool_raw "${next}")" || { parse_err "Invalid --${name}: expected bool"; return 1; }
                        shift
                    else
                        value="1"
                    fi

                elif (( $# < 2 )) || parse_is_flag "${next}"; then

                    parse_err "Missing value for --${name}"
                    return 1

                elif [[ "${type}" == "list" ]]; then

                    while (( $# > 1 )); do

                        parse_is_flag "${2}" && break

                        values+=( "${2}" )
                        shift

                    done

                else

                    value="${next}"
                    shift

                fi

                found="1"
                shift

                continue

            ;;
            "--${name}="*|"-${name}="*|"--${flag}="*|"-${flag}="*)

                if [[ "${type}" == "list" ]]; then

                    values+=( "${arg#*=}" )

                    while (( $# > 1 )); do

                        parse_is_flag "${2}" && break

                        values+=( "${2}" )
                        shift

                    done

                elif [[ "${type}" == "bool" ]]; then

                    value="$(parse_bool_raw "${arg#*=}")" || { parse_err "Invalid --${name}: expected bool"; return 1; }

                else

                    value="${arg#*=}"

                fi

                found="1"
                shift

                continue

            ;;
        esac
        if [[ -n "${short}" ]]; then

            case "${arg}" in
                "--no-${short}="*|"-no-${short}="*)

                    [[ "${type}" == "bool" ]] || { parse_err "Invalid --no-${short}: ${name} is not bool"; return 1; }

                    value="$(parse_bool_not "${arg#*=}")" || { parse_err "Invalid --no-${short}: expected bool"; return 1; }
                    found="1"

                    shift
                    continue

                ;;
                "--no-${short}"|"-no-${short}")

                    [[ "${type}" == "bool" ]] || { parse_err "Invalid --no-${short}: ${name} is not bool"; return 1; }

                    if (( $# > 1 )) && parse_bool_raw "${next}" >/dev/null 2>&1; then
                        value="$(parse_bool_not "${next}")" || return 1
                        shift
                    else
                        value="0"
                    fi

                    found="1"

                    shift
                    continue

                ;;
                "--${short}"|"-${short}")

                    if [[ "${type}" == "bool" ]]; then

                        if (( $# > 1 )) && ! parse_is_flag "${next}"; then
                            value="$(parse_bool_raw "${next}")" || { parse_err "Invalid -${short}: expected bool"; return 1; }
                            shift
                        else
                            value="1"
                        fi

                    elif (( $# < 2 )) || parse_is_flag "${next}"; then

                        parse_err "Missing value for -${short}"
                        return 1

                    elif [[ "${type}" == "list" ]]; then

                        while (( $# > 1 )); do

                            parse_is_flag "${2}" && break

                            values+=( "${2}" )
                            shift

                        done

                    else

                        value="${next}"
                        shift

                    fi

                    found="1"
                    shift

                    continue

                ;;
                "--${short}="*|"-${short}="*)

                    if [[ "${type}" == "list" ]]; then

                        values+=( "${arg#*=}" )

                        while (( $# > 1 )); do

                            parse_is_flag "${2}" && break

                            values+=( "${2}" )
                            shift

                        done

                    elif [[ "${type}" == "bool" ]]; then

                        value="$(parse_bool_raw "${arg#*=}")" || { parse_err "Invalid --${short}: expected bool"; return 1; }

                    else

                        value="${arg#*=}"

                    fi

                    found="1"
                    shift

                    continue

                ;;
            esac

        fi

        shift

    done

    if [[ "${found}" != "1" && "${index}" -gt 0 && "${index}" -le "${#args[@]}" ]]; then

        if [[ "${type}" == "list" ]]; then values+=( "${args[$(( index - 1 ))]}" )
        else value="${args[$(( index - 1 ))]}"
        fi

        found="1"

    fi
    if [[ "${found}" != "1" ]]; then

        [[ "${required}" == "1" ]] && { parse_err "Missing required argument: --${name}"; return 1; }
        return 1

    fi
    if [[ "${type}" == "list" ]]; then

        (( ${#values[@]} > 0 )) || { [[ "${required}" == "1" ]] && parse_err "Missing required argument: --${name}"; return 1; }
        printf '__parse_list_count__:%d\n' "${#values[@]}"

        for value in "${values[@]}"; do printf 'v:%s\n' "$(parse_encode "${value}")"; done
        return 0

    fi

    parse_typing "${type}" "${value}" "${name}" || return 1
    return 0

}
parse () {

    local sep="-1" rest_sep="-1" first_flag="-1" i="" j="" item="" raw_spec="" req="" raw="" rc=""
    local name="" type="" short="" extra="" default="" has_default="" msg="" err_file="" xtrace=""
    local arg="" next="" n="" f="" t="" s="" matched="0" value_index="" value_end=""

    local -a all=() args=() parse_args=() tail_rest=() specs=()
    local -a names=() types=() shorts=() reqs=() defaults=() has_defaults=()
    local -a arg_used=() spec_pos=() spec_end=() rest=()
    local -A used_shorts=()

    all=( "$@" )

    for i in "${!all[@]}"; do [[ "${all[i]}" == "--" ]] && sep="${i}"; done
    [[ "${sep}" -ge 0 ]] || { parse_fail "Missing parser separator: --"; return 1; }

    args=( "${all[@]:0:sep}" )
    specs=( "${all[@]:sep + 1}" )
    err_file="$(mktemp)" || { parse_fail "Failed to create temp file"; return 1; }

    if (( ! ${#specs[@]} > 0 )); then

        rm -f -- "${err_file}"
        parse_fail "Missing parser specs"
        return 1

    fi

    for raw_spec in "${specs[@]}"; do

        name="" type="" short="" extra="" default=""
        has_default="0" req="optional" item="${raw_spec}"

        if [[ -z "${item}" ]]; then

            rm -f -- "${err_file}"
            parse_fail "Empty parser spec"
            return 1

        fi
        if [[ "${item}" == :* ]]; then

            req="required"
            item="${item#:}"

        fi
        if [[ "${item}" == *"="* ]]; then

            default="${item#*=}"
            item="${item%%=*}"
            has_default="1"

        fi

        IFS=':' read -r name type short extra <<< "${item}"
        type="${type:-str}"

        if [[ -n "${extra}" ]]; then

            rm -f -- "${err_file}"
            parse_fail "Invalid spec ${item}: too many fields"
            return 1

        fi
        if [[ ! "${name}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then

            rm -f -- "${err_file}"
            parse_fail "Invalid variable name: ${name}"
            return 1

        fi
        if ! parse_validate "${type}"; then

            rm -f -- "${err_file}"
            parse_arg_err "${name}" "unknown type ${type}"

            parse_return
            return 1

        fi

        case "${short}" in
            "")
                short="${name:0:1}"
                [[ -n "${used_shorts[${short}]:-}" ]] && short="_"
            ;;
            -|_)
                short="_"
            ;;
            *)
                if [[ ! "${short}" =~ ^[A-Za-z_][A-Za-z0-9_-]*$ ]]; then

                    rm -f -- "${err_file}"
                    parse_arg_err "${name}" "short name ${short}"

                    parse_return
                    return 1

                fi
                if [[ -n "${used_shorts[${short}]:-}" ]]; then

                    rm -f -- "${err_file}"
                    parse_arg_err "${name}" "short name collision ${short}"

                    parse_return
                    return 1

                fi
            ;;
        esac

        [[ -n "${short}" && "${short}" != "_" ]] && used_shorts["${short}"]="1"

        names+=( "${name}" )
        types+=( "${type}" )
        shorts+=( "${short}" )
        reqs+=( "${req}" )
        defaults+=( "${default}" )
        has_defaults+=( "${has_default}" )

    done

    for i in "${!args[@]}"; do
        [[ "${args[i]}" == "--" ]] && { rest_sep="${i}"; break; }
    done

    if [[ "${rest_sep}" -ge 0 ]]; then
        parse_args=( "${args[@]:0:rest_sep}" )
        tail_rest=( "${args[@]:rest_sep + 1}" )
    else
        parse_args=( "${args[@]}" )
    fi

    for i in "${!parse_args[@]}"; do
        arg_used[i]="0"
    done
    for i in "${!parse_args[@]}"; do
        item="${parse_args[i]}"
        parse_is_flag "${item}" && { first_flag="${i}"; break; }
    done

    [[ "${first_flag}" -ge 0 ]] || first_flag="${#parse_args[@]}"
    j="0"

    for i in "${!names[@]}"; do

        spec_pos[i]="-1"
        spec_end[i]="-1"

        [[ "${j}" -lt "${first_flag}" ]] || continue

        spec_pos[i]="${j}"

        if [[ "${types[i]}" == "list" ]]; then

            spec_end[i]="$(( first_flag - 1 ))"

            while [[ "${j}" -lt "${first_flag}" ]]; do
                arg_used[j]="1"; (( j++ ))
            done

            continue

        fi

        spec_end[i]="${j}"
        arg_used[j]="1"

        (( j++ ))

    done

    i="${first_flag}"

    while (( i < ${#parse_args[@]} )); do

        arg="${parse_args[i]}"
        next="${parse_args[$(( i + 1 ))]:-}"
        matched="0"
        value_index=""
        value_end=""

        for j in "${!names[@]}"; do

            n="${names[j]}"
            f="${n//_/-}"
            s="${shorts[j]}"
            t="${types[j]}"

            case "${arg}" in
                "--no-${n}="*|"-no-${n}="*|"--no-${f}="*|"-no-${f}="*)
                    matched="1"
                ;;
                "--no-${n}"|"-no-${n}"|"--no-${f}"|"-no-${f}")
                    matched="1"

                    [[ "${t}" == "bool" && $(( i + 1 )) -lt ${#parse_args[@]} ]] && {
                        parse_bool_raw "${next}" >/dev/null 2>&1 && value_index="$(( i + 1 ))"
                    }
                ;;
                "--${n}="*|"-${n}="*|"--${f}="*|"-${f}="*)
                    matched="1"

                    if [[ "${t}" == "list" ]]; then
                        value_index="$(( i + 1 ))"
                        value_end="${i}"

                        while (( value_index < ${#parse_args[@]} )) && ! parse_is_flag "${parse_args[$value_index]}"; do
                            value_end="${value_index}"
                            (( value_index++ ))
                        done

                        if [[ "${value_end}" -ge "$(( i + 1 ))" ]]; then value_index="$(( i + 1 ))"
                        else value_index=""; value_end=""
                        fi
                    fi
                ;;
                "--${n}"|"-${n}"|"--${f}"|"-${f}")
                    matched="1"

                    if [[ "${t}" == "list" ]]; then

                        value_index="$(( i + 1 ))"
                        value_end="${i}"

                        while (( value_index < ${#parse_args[@]} )) && ! parse_is_flag "${parse_args[$value_index]}"; do
                            value_end="${value_index}"
                            (( value_index++ ))
                        done

                        if [[ "${value_end}" -ge "$(( i + 1 ))" ]]; then value_index="$(( i + 1 ))"
                        else value_index=""; value_end=""
                        fi

                    elif [[ "${t}" == "bool" && $(( i + 1 )) -lt ${#parse_args[@]} ]] && parse_bool_raw "${next}" >/dev/null 2>&1; then

                        value_index="$(( i + 1 ))"
                        value_end="${value_index}"

                    elif [[ "${t}" != "bool" && $(( i + 1 )) -lt ${#parse_args[@]} ]]; then

                        if ! parse_is_flag "${next}"; then
                            value_index="$(( i + 1 ))"
                            value_end="${value_index}"
                        fi

                    fi
                ;;
            esac

            if [[ "${matched}" == "0" && -n "${s}" && "${s}" != "_" ]]; then

                case "${arg}" in
                    "--no-${s}="*|"-no-${s}="*)
                        matched="1"
                    ;;
                    "--no-${s}"|"-no-${s}")
                        matched="1"

                        if [[ "${t}" == "bool" && $(( i + 1 )) -lt ${#parse_args[@]} ]] && parse_bool_raw "${next}" >/dev/null 2>&1; then
                            value_index="$(( i + 1 ))"
                        fi
                    ;;
                    "--${s}="*|"-${s}="*)
                        matched="1"

                        if [[ "${t}" == "list" ]]; then

                            value_index="$(( i + 1 ))"
                            value_end="${i}"

                            while (( value_index < ${#parse_args[@]} )) && ! parse_is_flag "${parse_args[$value_index]}"; do
                                value_end="${value_index}"
                                (( value_index++ ))
                            done

                            if [[ "${value_end}" -ge "$(( i + 1 ))" ]]; then value_index="$(( i + 1 ))"
                            else value_index=""; value_end=""
                            fi

                        fi
                    ;;
                    "--${s}"|"-${s}")
                        matched="1"

                        if [[ "${t}" == "list" ]]; then

                            value_index="$(( i + 1 ))"
                            value_end="${i}"

                            while (( value_index < ${#parse_args[@]} )) && ! parse_is_flag "${parse_args[$value_index]}"; do
                                value_end="${value_index}"
                                (( value_index++ ))
                            done

                            if [[ "${value_end}" -ge "$(( i + 1 ))" ]]; then value_index="$(( i + 1 ))"
                            else value_index=""; value_end=""
                            fi

                        elif [[ "${t}" == "bool" && $(( i + 1 )) -lt ${#parse_args[@]} ]] && parse_bool_raw "${next}" >/dev/null 2>&1; then

                            value_index="$(( i + 1 ))"
                            value_end="${value_index}"

                        elif [[ "${t}" != "bool" && $(( i + 1 )) -lt ${#parse_args[@]} ]]; then

                            if ! parse_is_flag "${next}"; then
                                value_index="$(( i + 1 ))"
                                value_end="${value_index}"
                            fi

                        fi
                    ;;
                esac

            fi

            [[ "${matched}" == "1" ]] && break

        done

        if [[ "${matched}" == "1" ]]; then

            arg_used[i]="1"

            if [[ -n "${value_index}" ]]; then

                if [[ -n "${value_end}" && "${value_end}" -ge "${value_index}" ]]; then

                    for j in $(seq "${value_index}" "${value_end}"); do
                        arg_used[j]="1"
                    done

                    i="$(( value_end + 1 ))"
                    continue

                fi

                arg_used[value_index]="1"

                i="$(( value_index + 1 ))"
                continue

            fi

        fi

        (( i++ ))

    done

    for i in "${!names[@]}"; do

        name="${names[i]}"
        type="${types[i]}"
        short="${shorts[i]}"
        req="${reqs[i]}"
        default="${defaults[i]}"
        has_default="${has_defaults[i]}"
        raw=""
        rc="0"
        msg=""
        xtrace="0"

        : > "${err_file}"
        case "$-" in *x*) xtrace="1"; set +x ;; esac

        if raw="$(parse_get "${parse_args[@]}" -- 0 "${name}" "${short}" "${type}" optional 2>"${err_file}")"; then rc="0"
        else rc="$?"
        fi

        [[ "${xtrace}" == "1" ]] && set -x

        if (( rc != 0 )); then

            if [[ -s "${err_file}" ]]; then

                msg="$(cat -- "${err_file}")"
                rm -f -- "${err_file}"

                [[ -n "${msg}" ]] && printf '%s\n' "${msg}" >&2

                parse_return
                return 1

            fi

            if [[ "${spec_pos[i]}" -ge 0 ]]; then

                j="${spec_pos[i]}"

                if [[ "${type}" == "list" ]]; then

                    raw="$(printf '__parse_list_count__:%d\n' "$(( spec_end[i] - spec_pos[i] + 1 ))")"

                    while [[ "${j}" -le "${spec_end[i]}" ]]; do

                        raw+=$'\n'
                        raw+="$(printf 'v:%s' "$(parse_encode "${parse_args[j]}")")"

                        (( j++ ))

                    done

                else

                    if ! raw="$(parse_typing "${type}" "${parse_args[j]}" "${name}")"; then

                        rm -f -- "${err_file}"
                        parse_return
                        return 1

                    fi

                fi

                rc="0"

            elif [[ "${has_default}" == "1" ]]; then

                if ! parse_emit_default "${name}" "${type}" "${default}"; then

                    rm -f -- "${err_file}"
                    parse_return
                    return 1

                fi

                continue

            elif [[ "${req}" == "required" ]]; then

                rm -f -- "${err_file}"
                parse_fail "Missing required argument: --${name}"
                return 1

            elif [[ "${type}" == "list" ]]; then

                printf 'local -a %s=()\n' "${name}"
                continue

            elif [[ "${type}" == "bool" ]]; then

                printf 'local %s=0\n' "${name}"
                continue

            elif [[ "${type}" == "int" || "${type}" == "uint" || "${type}" == "num" ]]; then

                printf 'local %s=0\n' "${name}"
                continue

            elif [[ "${type}" == "float" ]]; then

                printf 'local %s=0.0\n' "${name}"
                continue

            else

                printf 'local %s=""\n' "${name}"
                continue

            fi

        fi

        if [[ "${type}" == "list" ]]; then

            if ! parse_emit_list "${name}" "${raw}" "${req}"; then

                rm -f -- "${err_file}"
                parse_return
                return 1

            fi

        else

            if [[ "${req}" == "required" && -z "${raw}" ]]; then

                rm -f -- "${err_file}"
                parse_arg_err "${name}" "value is required"

                parse_return
                return 1

            fi

            printf 'local %s=%q\n' "${name}" "${raw}"

        fi

    done

    for i in "${!parse_args[@]}"; do
        [[ "${arg_used[i]}" == "0" ]] && rest+=( "${parse_args[i]}" )
    done

    rest+=( "${tail_rest[@]}" )

    printf 'local -a rest=('
    for item in "${rest[@]}"; do printf ' %q' "${item}"; done
    printf ' )\n'

    rm -f -- "${err_file}"
    return 0

}
