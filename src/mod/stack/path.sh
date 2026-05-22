
.. () {

    cd .. || return

}
.1 () {

    cd .. || return

}
.2 () {

    cd ../.. || return

}
.3 () {

    cd ../../.. || return

}
.4 () {

    cd ../../../.. || return

}
.5 () {

    cd ../../../../.. || return

}

home () {

    cd ~/ || return

}
temp () {

    cd /tmp || return

}
bin () {

    cd /usr/bin || return

}
binl () {

    cd ~/.local/bin || return

}
var () {

    cd /var || return

}
www () {

    cd /var/www || return

}
work () {

    local name="${1:-}" base=""

    if [[ -d /var/www/work ]]; then base="/var/www/work"
    else base="/var/www/projects"
    fi

    mkdir -p -- "${base}/${name}" || return
    cd -- "${base}/${name}"       || return

}
