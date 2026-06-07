
fine () {

    sync-vars    >/dev/null 2>&1 || true
    sync-secrets >/dev/null 2>&1 || true

    push --sync "$@"

}
ship () {

    fine --backup "$@"

}
gone () {

    local rc=0

    fine "$@" || { rc=$?; warn "push failed — locking anyway"; }
    lockscreen || rc=1

    return "${rc}"

}
