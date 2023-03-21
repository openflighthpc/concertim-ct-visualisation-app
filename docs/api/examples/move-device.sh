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
RACK_ID=${2}
FACING=${3}
START_U=${4}

BODY=$(jq --null-input \
    --arg facing "${FACING}" \
    --arg start_u "${START_U}" \
    --arg rack_id "${RACK_ID}" \
    '
{
    "device": {
        "location": {
            "facing": $facing,
            "rack_id": $rack_id|tonumber,
            "start_u": $start_u|tonumber
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

if [ "${HTTP_STATUS}" == "200" ] || [ "${HTTP_STATUS}" == "201" ] ; then
    cat "$BODY_FILE"
else
    echo "Device move failed" >&2
    cat "$BODY_FILE" >&2
    exit 1
fi
