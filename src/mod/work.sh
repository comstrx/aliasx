
gone () {

    sync-vars    >/dev/null 2>&1 || true
    sync-secrets >/dev/null 2>&1 || true

    push --sync "$@"

}
ship () {

    gone --backup "$@"

}
gameover () {

    local rc=0

    gone "$@" || { rc=$?; warn "gone failed — locking anyway"; }
    lock || rc=1

    return "${rc}"

}
