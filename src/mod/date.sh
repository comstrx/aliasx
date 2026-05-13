
dy () {

    date +%d

}
wk () {

    date +%V

}
mon () {

    date +%m

}
yr () {

    date +%Y

}

day () {

    date +%A

}
week () {

    date +%V

}
month () {

    date +%B

}
year () {

    date +%Y

}

now () {

    date +"%Y-%m-%d %H:%M:%S"

}
sec () {

    echo "${SECONDS}"

}
mill () {

    date +%s%3N

}
rand () {

    openssl rand -base64 "${1:-32}" | tr '+/' '-_' | tr -d '=\n'
    echo

}
