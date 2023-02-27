#!/bin/bash

set -e
set -o pipefail
# set -x

# The base URL against which relative URLs are constructed.
BASE_URL="https://localhost:9444/--/api/v1"
# BASE_URL="https://command.concertim.alces-flight.com/mrd"

# Currently the API is not authenticated.  When authentication is added, it
# will be via a bearer token that will be gained via a HTTP API request.
# AUTH_TOKEN=$(curl -s -k -X POST "${BASE_URL}/sessions" -d '{}' | jq -r .token)
AUTH_TOKEN=""

NAME=${1}
RACK_ID=${2}
FACING=${3}
START_U=${4}

BODY=$(jq --null-input \
    --arg name "${NAME}" \
    --arg description "This is ${NAME}" \
    --arg facing "${FACING}" \
    --arg start_u "${START_U}" \
    --arg rack_id "${RACK_ID}" \
    '
{
    "device": {
        "name": $name,
        "description": $description,
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
exec 3>&1 
TEMP_FILE=$(mktemp)
HTTP_STATUS=$(
curl -s -k \
    -w "%{http_code}" \
    -o >(cat > "${TEMP_FILE}") \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer ${AUTH_TOKEN}" \
    -X POST "${BASE_URL}/nodes" \
    -d "${BODY}"
)

if [ "${HTTP_STATUS}" == "200" ] || [ "${HTTP_STATUS}" == "201" ] ; then
    cat "$TEMP_FILE"
else
    echo "Device creation failed" >&2
    cat "$TEMP_FILE" >&2
    exit 1
fi
