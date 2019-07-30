#!/bin/sh

BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BOLD=`tput bold`
RESET=`tput sgr0`

log_raw () {
    local COLOR="${WHITE}"
    local LEVEL="${1}"
    local MESSAGE="${2}"
    case "${LEVEL}" in
        info)
            COLOR="${BLUE}"
            ;;
        warn)
            COLOR="${YELLOW}"
            ;;
        fatal)
            COLOR="${RED}"
            ;;
        *)
            LEVEL="debug"
            ;;
    esac
    LEVEL="${LEVEL}     "
    echo "[$(date +%T)] ${COLOR}$(echo "${LEVEL:0:5}" | tr '[:lower:]' '[:upper:]')${RESET} ${MESSAGE}";
}

log () {
    log_raw "debug" "${1}"
}

info () {
    log_raw "info" "${1}";
}

warn () {
    log_raw "warn" "${1}";
}

die () {
    log_raw "fatal" "${1}";
    exit 1;
}

die_unless_forced () {
    if [ ! -z "$1" ]; then
        log_raw "warn" "$2";
        return;
    fi
    
    log_raw "fatal" "$2";
    die "Use -f to forcibly upgrade.";
}