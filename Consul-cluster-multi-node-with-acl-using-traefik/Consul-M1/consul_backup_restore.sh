#!/usr/bin/env bash

MASTER_TOKEN=$(python -c 'import sys; import json; print (json.load(sys.stdin)["acl"]["tokens"]["master"])' < ./consul/config/consul-config.json)
CONSUL_HOST="consul_master"

echo "$(date +"%Y-%m-%d %H:%M:%S"): Starting Restore for Consul infrastructure"

docker exec -e CONSUL_HTTP_TOKEN="${MASTER_TOKEN}" -it "${CONSUL_HOST}" consul snapshot restore consul/config/backup.snap

echo "$(date +"%Y-%m-%d %H:%M:%S"): Consul Restore finish successfully"