#!/bin/bash

# Directory with LTSP data and scripts
LTSPDATA="/etc/ltsp/data"

# Setup SSH Daemon
ssh-keygen -A

# Setup sudo with no password for ltsp user
echo "%sudo ALL=(ALL:ALL) NOPASSWD:ALL" >/etc/sudoers.d/90-ltsp-sudo-group
chmod 0440 /etc/sudoers.d/90-ltsp-sudo-group

# Setup timezone
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime

# Setup sysctl settings
if [ -f "${LTSPDATA}/sysctl.conf" ]; then
    cp -f ${LTSPDATA}/sysctl.conf /etc/sysctl.d/99-sysctl.conf
fi

# Setup modules
if [ -f "${LTSPDATA}/modules" ]; then
    cp -f ${LTSPDATA}/modules /etc/modules
fi

# Setup docker config
if [ -f "${LTSPDATA}/docker.json" ]; then
    mkdir -p /etc/docker
    cp -f ${LTSPDATA}/docker.json /etc/docker/daemon.json
fi

# Setup users
for userpath in ${LTSPDATA}/users/*/; do
    # Setup hashed password for user and copy user-files to user home directory
    user=$(basename "$userpath")
    echo "Initializing user: ${user}..."
    ${LTSPDATA}/../scripts/pre-init-user.sh ${user}
done

# Cleanup LTSP data directory
find ${LTSPDATA} -empty -type d -delete
