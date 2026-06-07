
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
.6 () {

    cd ../../../../../.. || return

}
.7 () {

    cd ../../../../../../.. || return

}
.8 () {

    cd ../../../../../../../.. || return

}
.9 () {

    cd ../../../../../../../../.. || return

}
.10 () {

    cd ../../../../../../../../../.. || return

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

    local name="${1:-}" dir="/var/www"

    if [[ -n "${name}" ]]; then

        if [[ -e "/var/www/${name}" ]]; then dir="/var/www/${name}"
        elif [[ -e "/var/www/projects/${name}" ]]; then dir="/var/www/projects/${name}"
        elif [[ -e "/var/www/tools/${name}" ]]; then dir="/var/www/tools/${name}"
        fi

    fi

    cd -- "${dir}" || return

}
project () {

    local name="${1:-}" dir="/var/www/projects"
    [[ -n "${name}" ]] && dir="${dir}/${name}"

    cd -- "${dir}" || return

}
tool () {

    local name="${1:-}" dir="/var/www/tools"
    [[ -n "${name}" ]] && dir="${dir}/${name}"

    cd -- "${dir}" || return

}
