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

RACK_ID=${1}
NAME=${2}
HEIGHT=${3}

# The metadata below is hardcoded but it could be any valid JSON document.  The
# metadata will be set to exactly this document; any values not present will be
# removed.

BODY=$(jq --null-input \
    --arg name "${NAME}" \
    --arg u_height ${HEIGHT} \
    '
{
    "rack": {
        "name": $name,
        "u_height": $u_height|tonumber,
        "status": "ACTIVE",
        "metadata": {
          "status": "CREATE_COMPLETED",
          "stack_id": "92927d62-ebcf-4faf-a8ab-4068ca3911f3"
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
    -X PATCH "${BASE_URL}/racks/${RACK_ID}" \
    -d "${BODY}"
)

if [ "${HTTP_STATUS}" == "200" ] || [ "${HTTP_STATUS}" == "202" ] ; then
    cat "$BODY_FILE"
else
    echo "Rack update failed" >&2
    cat "$BODY_FILE" >&2
    exit 1
fi
