#!/usr/bin/env bash

MASTER_TOKEN=$(python -c 'import sys; import json; print (json.load(sys.stdin)["acl"]["tokens"]["master"])' < ./consul/config/consul-config.json)
AGENT_TOKEN="your_uuid_agent token"
REGISTRY_TOKEN="your_uuid_registry token"
CONSUL_SERVICE_TOKEN="your_uuid_service_consul token"
CONSUL_HOST="consul_master"

echo "$(date +"%Y-%m-%d %H:%M:%S"): Starting the basic Consul infrastructure"
docker-compose up -d >/dev/null 2>&1


sleep 20
CONSUL_LEADER=$(curl -s localhost:8500/v1/status/leader)
while [[ "${CONSUL_LEADER}" == "\"\"" ]];do
    sleep 1
    CONSUL_LEADER=$(curl -s localhost:8500/v1/status/leader)
done

sleep 5
echo "$(date +"%Y-%m-%d %H:%M:%S"): Configure Agent ACL"
docker exec -e CONSUL_HTTP_TOKEN="${MASTER_TOKEN}" -it "${CONSUL_HOST}" consul acl policy create -name agent-write-policy -description "Policy capable of consul agent write new items" -rules @/tmp/hcl/agent-policy-write.hcl >/dev/null
docker exec -e CONSUL_HTTP_TOKEN="${MASTER_TOKEN}" -it "${CONSUL_HOST}" consul acl token create -description "Agent token" -policy-name agent-write-policy -secret="${AGENT_TOKEN}" >/dev/null
docker exec -e CONSUL_HTTP_TOKEN="${MASTER_TOKEN}" -it "${CONSUL_HOST}" consul acl set-agent-token agent "${AGENT_TOKEN}" >/dev/null

sleep 5
echo "$(date +"%Y-%m-%d %H:%M:%S"): Configure Registry ACL" 
docker exec -e CONSUL_HTTP_TOKEN="${MASTER_TOKEN}" -it "${CONSUL_HOST}" consul acl policy create -name registry-policy -description "Policy capable of registry new services using registry" -rules @/tmp/hcl/registry-policy.hcl >/dev/null
docker exec -e CONSUL_HTTP_TOKEN="${MASTER_TOKEN}" -it "${CONSUL_HOST}" consul acl token create -description "Registry token" -policy-name registry-policy -secret="${REGISTRY_TOKEN}" >/dev/null
docker exec -e CONSUL_HTTP_TOKEN="${MASTER_TOKEN}" -it "${CONSUL_HOST}" consul acl set-agent-token agent "${REGISTRY_TOKEN}" >/dev/null

sleep 5
echo "$(date +"%Y-%m-%d %H:%M:%S"): Configure Consul Service ACL"
docker exec -e CONSUL_HTTP_TOKEN="${MASTER_TOKEN}" -it "${CONSUL_HOST}" consul acl policy create -name consul-service-policy -description "Policy capable of create consul service" -rules @/tmp/hcl/consul-service.hcl >/dev/null
docker exec -e CONSUL_HTTP_TOKEN="${MASTER_TOKEN}" -it "${CONSUL_HOST}" consul acl token create -description "Consul Service token" -policy-name registry-policy -secret="${CONSUL_SERVICE_TOKEN}" >/dev/null
docker exec -e CONSUL_HTTP_TOKEN="${MASTER_TOKEN}" -it "${CONSUL_HOST}" consul acl set-agent-token agent "${CONSUL_SERVICE_TOKEN}" >/dev/null

sleep 5
echo "$(date +"%Y-%m-%d %H:%M:%S"): Configure Anonymous ACL"
docker exec -e CONSUL_HTTP_TOKEN="${MASTER_TOKEN}" -it "${CONSUL_HOST}" consul acl policy create -name anonymous-read-policy -description "Policy capable of allow anonymous user read items" -rules @/tmp/hcl/anonymous-read.hcl >/dev/null
docker exec -e CONSUL_HTTP_TOKEN="${MASTER_TOKEN}" -it "${CONSUL_HOST}" consul acl token update -id anonymous -policy-name=anonymous-read-policy >/dev/null

echo "$(date +"%Y-%m-%d %H:%M:%S"): Consul Cluster configured completely"