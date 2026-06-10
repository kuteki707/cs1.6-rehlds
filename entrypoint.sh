#!/bin/bash
set -e

echo "Starting ReHLDS Match Server..."
echo "Map: ${MAP}"
echo "Max Players: ${MAXPLAYERS}"
echo "Tickrate: ${TICKRATE}"

export LD_LIBRARY_PATH=".:$LD_LIBRARY_PATH"

exec ./hlds_run \
    -game cstrike \
    -strictportbind \
    -port 27015 \
    +clientport 27005 \
    +map "${MAP}" \
    +maxplayers "${MAXPLAYERS}" \
    +sys_ticrate "${TICKRATE}" \
    -nomaster \
    -insecure
