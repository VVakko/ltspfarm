#!/bin/bash

# Directory with LTSP data and scripts
LTSPDATA="/etc/ltsp/data"
user=$1

# Checking user parameter
if [ -z ${user} ]; then
    echo "Nothing to do."
    exit 1
fi

# Creating user if it doesn't exists
getent passwd ${user} >/dev/null
if [ ! $? -eq 0 ]; then
    useradd ${user} -m -s /bin/bash
fi

# Setup user groups
filename="${LTSPDATA}/users/${user}.groups.txt"
if [ -f $filename ]; then
    usermod --groups=$(cat $filename) ${user} \
    && rm -f $filename
fi

# Setup hashed password for ltsp user (use `openssl passwd -6` to generate one)
filename="${LTSPDATA}/users/${user}.password.txt"
if [ -f $filename ]; then
    usermod --password=$(cat $filename) ${user} \
    && rm -f $filename
fi

# Copy user-files to user home directory
userdir="${LTSPDATA}/users/${user}"
if [ -d ${userdir} ]; then
    home=$(getent passwd ${user} | cut -d: -f6)
    cp -prf ${userdir}/* ${home} 2>/dev/null
    cp -prf ${userdir}/.[^.]* ${home} 2>/dev/null
    chown -R ${user}: ${home}
    if [ -L "${userdir}" ]; then
        rm -f ${userdir}
    else
        rm -rf ${userdir}
    fi
fi
