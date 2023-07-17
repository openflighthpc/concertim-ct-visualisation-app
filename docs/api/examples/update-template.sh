#!/bin/bash

set -e
set -o pipefail
# set -x

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# The base URL against which relative URLs are constructed.
CONCERTIM_HOST=${CONCERTIM_HOST:-command.concertim.alces-flight.com}
BASE_URL="https://${CONCERTIM_HOST}/api/v1"

# Use the specified AUTH_TOKEN or generate one.  If AUTH_TOKEN is being
# generated LOGIN and PASSWORD environment variables must be set.
AUTH_TOKEN=${AUTH_TOKEN:-$("${SCRIPT_DIR}"/get-auth-token.sh)}

# The template's height cannot be updated.  This avoids an issue where changing
# the height of a template could result in overlapping devices in a rack.
TEMPLATE_ID=${1}
NAME=${2}
DESCRIPTION=${3}
FOREIGN_ID=${4}
VCPUS=${5}
RAM=${6}
DISK=${7}


BODY=$(jq --null-input \
    --arg name "${NAME}" \
    --arg description "${DESCRIPTION}" \
    --arg foreign_id "${FOREIGN_ID}" \
    --arg vcpus "${VCPUS}" \
    --arg ram "${RAM}" \
    --arg disk "${DISK}" \
    '
{
    "template": {
        "name": $name,
        "description": $description,
        "foreign_id": $foreign_id,
        "vcpus": $vcpus|(try tonumber catch ""),
        "ram": $ram|(try tonumber catch ""),
        "disk": $disk|(try tonumber catch "")
    }
}
' \
  | jq '{template: .template | with_entries(select(.value != ""))}'
)

# Run curl with funky redirection to capture response body and status code.
BODY_FILE=$(mktemp)
HTTP_STATUS=$(
curl -s -k \
    -w "%{http_code}" \
    -o >(cat > "${BODY_FILE}") \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    -H "Authorization: Bearer ${AUTH_TOKEN}" \
    -X PATCH "${BASE_URL}/templates/${TEMPLATE_ID}" \
    -d "${BODY}"
)

if [ "${HTTP_STATUS}" == "200" ] || [ "${HTTP_STATUS}" == "202" ] ; then
    cat "$BODY_FILE"
else
    echo "Template update failed" >&2
    cat "$BODY_FILE" >&2
    exit 1
fi
