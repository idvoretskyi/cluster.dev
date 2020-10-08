#!/bin/bash
set -x
set -e
# Login
LOGINRESPONSE=$(curl -s 'https://${rancher_domain}/v3-public/localProviders/local?action=login' -H 'content-type: application/json' --data-binary '{"username":"admin","password":"admin"}' --insecure)
LOGINTOKEN=$(echo $${LOGINRESPONSE} | jq -r .token)

curl -s 'https://${rancher_domain}/v3/users?action=changepassword' -H 'content-type: application/json' -H "Authorization: Bearer $LOGINTOKEN" --data-binary '{"currentPassword":"admin","newPassword":"${rancher_password}"}' --insecure

APIRESPONSE=$(curl -s 'https://${rancher_domain}/v3/token' -H 'content-type: application/json' -H "Authorization: Bearer $${LOGINTOKEN}" --data-binary '{"type":"token","description":"automation"}' --insecure)
APITOKEN=$(echo $${APIRESPONSE} | jq -r .token)

# CACHECKSUM=$(curl -s -H "Authorization: Bearer $${APITOKEN}" https://${rancher_domain}/v3/settings/cacerts | jq -r .value | sha256sum | awk '{ print $1 }')

# Set server-url
RANCHER_SERVER=https://${rancher_domain}
curl -s 'https://${rancher_domain}/v3/settings/server-url' -H 'content-type: application/json' -H "Authorization: Bearer $${APITOKEN}" -X PUT --data-binary '{"name":"server-url","value":"'$${RANCHER_SERVER}'"}' --insecure > /dev/null

