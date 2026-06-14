#!/bin/bash
set -e

echo "Starting ReHLDS Match Server..."
echo "Port: ${PORT:-27015}"
echo "Client Port: ${CLIENTPORT:-27005}"
echo "Map: ${MAP}"
echo "Max Players: ${MAXPLAYERS}"
echo "Tickrate: ${TICKRATE}"

export LD_LIBRARY_PATH=".:$LD_LIBRARY_PATH"

exec ./hlds_run \
    -game cstrike \
    -strictportbind \
    -port "${PORT:-27015}" \
    +clientport "${CLIENTPORT:-27005}" \
    +map "${MAP}" \
    +maxplayers "${MAXPLAYERS}" \
    +sys_ticrate "${TICKRATE}" \
    -nomaster \
    -insecure
#    -bots
