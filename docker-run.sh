#!/bin/bash

set -e

VOLUME=${VOLUME:-/data}
VOLUME_NAME=${VOLUME_NAME:-data}
OWNER=${OWNER:-root}
GROUP=${GROUP:-root}
ENCFS_ROOT=${ENCFS_ROOT:-$VOLUME/encfs}
ENCFS_MNT=${ENCFS_MNT:-/encfs}

function echoError ()
{
	printf "\033[0;31mERROR: $1 \033[0m\n"
}

function checkEnvironmentVariable ()
{
	VAR=$1
	if [ -z "${!VAR}" ]; then
		echoError "Please set environment variable $VAR"
		exit 1
	fi
}

checkEnvironmentVariable USER
checkEnvironmentVariable PASS
checkEnvironmentVariable CRYPT_PASS

mkdir -p "${ENCFS_MNT}"
mkdir -p "${ENCFS_ROOT}"

echo "$CRYPT_PASS" > /crypt_pass

encfs --extpass="cat /crypt_pass" "${ENCFS_ROOT}" "${ENCFS_MNT}"

rm -f /crypt_pass

[ -f /etc/rsyncd.conf ] || cat <<EOF > /etc/rsyncd.conf
uid = ${OWNER}
gid = ${GROUP}
use chroot = yes
log file = /dev/stdout
reverse lookup = no

[${VOLUME_NAME}]
    read only = false
    path = ${ENCFS_MNT}
    comment = docker volume
    auth users = ${USER}
    secrets file = /etc/rsyncd.secrets
EOF

[ -f /etc/rsyncd.secrets ] || cat <<EOF > /etc/rsyncd.secrets
${USER}:${PASS}
EOF

chmod 750 /etc/rsyncd.secrets


exec /usr/bin/rsync --no-detach --daemon --config /etc/rsyncd.conf "$@"
