#!/bin/bash

# LTSP Debug Log File
log="/run/ltsp/debug.log"

# Copy special shared folder 'docker' with rsync via ssh to local '/srv' folder
key="/tmp/id_rsa"
curl -s http://server:6980/ltsp/id_rsa >${key} 2>>${log}
chmod og-rwx ${key}
rsync -Pav -e "ssh -i ${key} -p 6922 \
    -o LogLevel=ERROR -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
    ltsp@server:/data/docker/ /srv/ >>${log} 2>&1
rm -f ${key}
