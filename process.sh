#!/bin/bash

trap "{ kill -INT `cat /run/slapd/slapd.pid` || true }" SIGINT SIGTERM EXIT

# set -x (bash debug) if log level is trace
# https://github.com/osixia/docker-light-baseimage/blob/stable/image/tool/log-helper
log-helper level eq trace && set -x

# Reduce maximum number of number of open file descriptors to 1024
# otherwise slapd consumes two orders of magnitude more of RAM
# see https://github.com/docker/docker/issues/8231
ulimit -n $LDAP_NOFILE

CONTAINER_SERVICE_DIR="${CONTAINER_SERVICE_DIR:-/container/service}"
LDAP_TLS_KEY_FILENAME="${LDAP_TLS_KEY_FILENAME:-ldap.key}"

if [ -z "$FILE_TO_WAIT_FOR" ]; then
    # By default, we'll wait for the privkey file
    FILE_TO_WAIT_FOR="${CONTAINER_SERVICE_DIR}/slapd/assets/certs/${LDAP_TLS_KEY_FILENAME}"
fi

while true; do
    exec /usr/sbin/slapd -h "ldap://$HOSTNAME ldaps://$HOSTNAME ldapi:///" -u openldap -g openldap -d $LDAP_LOG_LEVEL &
    PID=$!
    inotifywait "$FILE_TO_WAIT_FOR"
    kill -INT `cat /run/slapd/slapd.pid` $PID
done
