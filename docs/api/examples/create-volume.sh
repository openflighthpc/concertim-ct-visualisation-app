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

NAME=${1}
RACK_ID=${2}
FACING=${3}
START_U=${4}

VOLUME_TEMPLATE_ID=$( "${SCRIPT_DIR}/list-templates.sh" | jq -r '.[] | select(.tag == "volume") | .id' )

if [ -z "${VOLUME_TEMPLATE_ID}" ]; then
    echo "Couldn't find a template with tag='volume'"
    exit 1
fi

# The metadata below is hardcoded but it could be any valid JSON document.

BODY=$(jq --null-input \
    --arg name "${NAME}" \
    --arg description "This is ${NAME} volume" \
    --arg facing "${FACING}" \
    --arg start_u "${START_U}" \
    --arg rack_id "${RACK_ID}" \
    --arg template_id "${VOLUME_TEMPLATE_ID}" \
    '
{
    "template_id": $template_id,
    "device": {
        "name": $name,
        "type": "Volume",
        "description": $description,
        "location": {
            "facing": $facing,
            "rack_id": $rack_id,
            "start_u": $start_u|tonumber
        },
        "status": "IN_PROGRESS",
        "metadata": {
          "openstack_instance_id": "8f4e9068-5a39-4717-8a83-6b95e01031eb",
          "status": ["build", "scheduling", ""]
        },
        "details": {
            "type": "Device::VolumeDetails",
            "bootable": false,
            "encrypted": false,
            "size": 2
        }
    }
}
'
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
    -X POST "${BASE_URL}/nodes" \
    -d "${BODY}"
)

if [ "${HTTP_STATUS}" == "200" ] || [ "${HTTP_STATUS}" == "201" ] ; then
    cat "$BODY_FILE"
else
    echo "Device creation failed" >&2
    cat "$BODY_FILE" >&2
    exit 1
fi
