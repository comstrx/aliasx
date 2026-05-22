
pids () {

    local name="${1:-}" line="" pid="" owner="" pargs="" uid=""
    local -a cmd=()

    [[ -n "${name}" ]] || { err "Usage: pids <process-name>"; return; }
    uid="$(id -u 2>/dev/null || true)"

    if ps axo pid=,ppid=,uid=,args= >/dev/null 2>&1; then

        cmd=( ps axo 'pid=,ppid=,uid=,args=' )

    elif ps -eo pid=,ppid=,uid=,args= >/dev/null 2>&1; then

        cmd=( ps -eo 'pid=,ppid=,uid=,args=' )

    else

        command -v pgrep >/dev/null 2>&1 || return 0

        while IFS= read -r pid; do

            [[ "${pid}" =~ ^[0-9]+$ ]] || continue
            [[ "${pid}" == "$$" || "${pid}" == "${BASHPID:-}" || "${pid}" == "${PPID:-}" ]] && continue

            out "${pid}"

        done < <(
            if [[ -n "${uid}" ]]; then pgrep -u "${uid}" -f -- "${name}" 2>/dev/null
            else pgrep -f -- "${name}" 2>/dev/null
            fi || true
        )

        return 0

    fi

    while IFS= read -r line || [[ -n "${line}" ]]; do

        read -r pid _ owner pargs <<< "${line}"

        [[ "${pid}" =~ ^[0-9]+$ ]] || continue
        [[ -z "${uid}" || "${owner}" == "${uid}" ]] || continue
        [[ "${pargs}" == *"${name}"* ]] || continue
        [[ "${pid}" == "$$" || "${pid}" == "${BASHPID:-}" || "${pid}" == "${PPID:-}" ]] && continue

        out "${pid}"

    done < <("${cmd[@]}")

}
show () {

    local name="${1:-}" pid="" pid_csv=""
    local -a pids=()

    [[ -n "${name}" ]] || { err "Usage: show <process-name>"; return; }

    while IFS= read -r pid; do [[ -n "${pid}" ]] && pids+=( "${pid}" ); done < <(pids "${name}")
    [[ "${#pids[@]}" -gt 0 ]] || { warn "No process found: ${name}"; return; }

    pid_csv="$(IFS=,; printf '%s' "${pids[*]}")"

    ps -p "${pid_csv}" -o pid,ppid,user,%cpu,%mem,etime,stat,args 2>/dev/null || ps -p "${pid_csv}" -o pid,ppid,user,stat,args

}
stop () {

    local name="${1:-}" pid=""
    local -a pids=() alive=() left=()

    [[ -n "${name}" ]] || { err "Usage: stop <process-name>"; return; }

    while IFS= read -r pid; do [[ -n "${pid}" ]] && pids+=( "${pid}" ); done < <(pids "${name}")
    [[ "${#pids[@]}" -gt 0 ]] || { warn "No process found: ${name}"; return; }

    kill -TERM "${pids[@]}" 2>/dev/null || true
    sleep 1

    for pid in "${pids[@]}"; do kill -0 "${pid}" 2>/dev/null && alive+=( "${pid}" ); done
    (( ${#alive[@]} == 0 )) || kill -KILL "${alive[@]}" 2>/dev/null || true

    for pid in "${pids[@]}"; do kill -0 "${pid}" 2>/dev/null && left+=( "${pid}" ); done
    (( ${#left[@]} == 0 )) || { err "Failed to stop: ${name}"; return; }

    succ "Stopped: ${name}"

}
