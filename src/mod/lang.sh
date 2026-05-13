
np () {

    npm "$@"

}
npi () {

    npm install "$@"

}
npd () {

    npm run dev "$@"

}
npb () {

    npm run build "$@"

}
nps () {

    npm run build
    npm start "$@"

}

pa () {

    php artisan "$@"

}
pam () {

    php artisan migrate "$@"

}
pads () {

    php artisan db:seed "$@"

}
pamf () {

    php artisan migrate:fresh "$@"

}
pams () {

    php artisan migrate --seed "$@"

}
pas () {

    php artisan serve --host=0.0.0.0 --port=8000 "$@"

}
paq () {

    php artisan queue:work --tries=3 "$@"

}
pat () {

    php artisan test "$@"

}
pak () {

    php artisan tinker "$@"

}
pah () {

    php artisan horizon "$@"

}
par () {

    php artisan reverb:start "$@"

}
pao () {

    php artisan octane:start --server=swoole --host=127.0.0.1 --port=8000 "$@"

}
paf () {

    php artisan cache:clear
    php artisan config:clear
    php artisan route:clear
    php artisan event:clear
    clear

}

py () {

    python "$@"

}
pyr () {

    python -m "${1:-main}" "${@:2}"

}
pyrg () {

    PYTHON_GIL=0 python -m "${1:-main}" "${@:2}"

}
pya () {

    source "${1:-venv}/bin/activate"

}
pyd () {

    deactivate 2>/dev/null || true

}
pyv12 () {

    python3.12 -m venv "${1:-venv}"
    succ "Created Python 3.12 venv in ${1:-venv}"

}
pyv13 () {

    python3.13 -m venv "${1:-venv}"
    succ "Created Python 3.13 venv in ${1:-venv}"

}
pyv14 () {

    python3.14 -m venv "${1:-venv}"
    succ "Created Python 3.14 venv in ${1:-venv}"

}
pyvg () {

    /opt/python-3.14t/bin/python3.14t -m venv "${1:-venv}"
    succ "Created Python 3.14t Free-Threaded venv in ${1:-venv}"

}

c () {

    cargo "$@"

}
cb () {

    cargo build "$@"

}
cbr () {

    cargo build --release "$@"

}
cr () {

    cargo run "$@"

}
crr () {

    cargo run --release "$@"

}
cc () {

    cargo check "$@"

}
ct () {

    cargo test "$@"

}
cl () {

    cargo clippy -- -D warnings "$@"

}
cf () {

    cargo fmt "$@"

}
cw () {

    cargo watch -x check -x test -x run "$@"

}

d () {

    docker "$@"

}
di () {

    docker images "$@"

}
dl () {

    docker logs -f --tail=100 "$@"

}
dx () {

    docker exec -it "$@"

}
dr () {

    docker system prune -af --volumes "$@"

}
dps () {

    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" "$@"

}
dpa () {

    docker ps -a "$@"

}
ds () {

    local -a ids=()

    mapfile -t ids < <(docker ps -q)

    [[ "${#ids[@]}" -gt 0 ]] && docker stop "${ids[@]}" "$@"
    
}

dc () {

    docker compose "$@"

}
dcu () {

    docker compose up -d "$@"

}
dcd () {

    docker compose down "$@"

}
dcr () {

    docker compose restart "$@"

}
dcl () {

    docker compose logs -f --tail=100 "$@"

}
dcb () {

    docker compose build "$@"

}
dcs () {

    docker compose ps "$@"

}
