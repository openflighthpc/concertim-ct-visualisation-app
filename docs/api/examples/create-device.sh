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
TEMPLATE_ID=${5}

# The metadata below is hardcoded but it could be any valid JSON document.

BODY=$(jq --null-input \
    --arg name "${NAME}" \
    --arg description "This is ${NAME}" \
    --arg facing "${FACING}" \
    --arg start_u "${START_U}" \
    --arg rack_id "${RACK_ID}" \
    --arg template_id "${TEMPLATE_ID}" \
    '
{
    "template_id": $template_id,
    "device": {
        "name": $name,
        "description": $description,
        "location": {
            "facing": $facing,
            "rack_id": $rack_id|tonumber,
            "start_u": $start_u|tonumber
        },
        "metadata": {
          "key_one": "value_one",
          "key_two": 2
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
