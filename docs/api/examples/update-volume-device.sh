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

DEVICE_ID=${1}
NAME=${2}

# The metadata below is hardcoded but it could be any valid JSON document.  The
# metadata will be set to exactly this document; any values not present will be
# removed.

BODY=$(jq --null-input \
    --arg name "${NAME}" \
    --arg description "This is ${NAME}" \
    '
{
    "device": {
        "details": {
            "type": "Device::VolumeDetails",
            "availability_zone": "nova",
            "bootable": "False",
            "encrypted": "False",
            "size": 17,
            "volume_type": "__DEFAULT__"
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
    -X PATCH "${BASE_URL}/devices/${DEVICE_ID}" \
    -d "${BODY}"
)

if [ "${HTTP_STATUS}" == "200" ] || [ "${HTTP_STATUS}" == "202" ] ; then
    cat "$BODY_FILE"
else
    echo "Device update failed" >&2
    cat "$BODY_FILE" >&2
    exit 1
fi
