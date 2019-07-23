#!/bin/bash

trap "{ kill -INT `cat /run/slapd/slapd.pid` ; exit }" SIGINT SIGTERM

# set -x (bash debug) if log level is trace
# https://github.com/osixia/docker-light-baseimage/blob/stable/image/tool/log-helper
log-helper level eq trace && set -x

# Reduce maximum number of number of open file descriptors to 1024
# otherwise slapd consumes two orders of magnitude more of RAM
# see https://github.com/docker/docker/issues/8231
ulimit -n $LDAP_NOFILE

CONTAINER_SERVICE_DIR="${CONTAINER_SERVICE_DIR:-/container/service}"
LDAP_TLS_KEY_FILENAME="${LDAP_TLS_KEY_FILENAME:-privkey.pem}"

if [ "${LDAP_TLS,,}" != "true" ] && [ -z "$FILE_TO_WAIT_FOR" ]; then
    # If TLS is not enabled and we don't have a file to wait for, there's no use in defaulting to waiting for a cert update
    #  so we can just start slapd and be done with it.
    exec /usr/sbin/slapd -h "ldap://$HOSTNAME ldaps://$HOSTNAME ldapi:///" -u openldap -g openldap -d $LDAP_LOG_LEVEL
    exit $?
done

if [ -z "$FILE_TO_WAIT_FOR" ]; then
    # By default, we'll wait for the privkey file
    FILE_TO_WAIT_FOR="${CONTAINER_SERVICE_DIR}/slapd/assets/certs/${LDAP_TLS_KEY_FILENAME}"
fi

HASH=`md5sum "${FILE_TO_WAIT_FOR}"`
PIDFILE="/run/slapd/slapd.pid"

function stop_if_running() {
    if [ -f "${PIDFILE}" ] ; then
        kill -INT `cat ${PIDFILE}`
    fi
    killall -INT slapd
}

function start_if_not_running() {
    CURRENT_PID=`pgrep -F "${PIDFILE}" 2>/dev/null || true`
    if [ -z "${CURRENT_PID}" ] ; then
        exec /usr/sbin/slapd -h "ldap://$HOSTNAME ldaps://$HOSTNAME ldapi:///" -u openldap -g openldap -d $LDAP_LOG_LEVEL &
    fi
}

while true; do
    start_if_not_running

    inotifywait "$FILE_TO_WAIT_FOR" -e MODIFY

    NEWHASH=`md5sum ${FILE_TO_WAIT_FOR}`

    if [ "${HASH}" != "${NEWHASH}" ] ; then
        stop_if_running
        HASH="${NEWHASH}"
    fi
done

stop_if_running
exit 0
