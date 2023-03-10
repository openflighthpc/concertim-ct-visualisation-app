#!/bin/bash

set -e
set -o pipefail
# set -x

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# The base URL against which relative URLs are constructed.
CONCERTIM_HOST=${CONCERTIM_HOST:-command.concertim.alces-flight.com}
BASE_URL="https://${CONCERTIM_HOST}/--/api/v1"

# Use the specified AUTH_TOKEN or generate one.  If AUTH_TOKEN is being
# generated LOGIN and PASSWORD environment variables must be set.
AUTH_TOKEN=${AUTH_TOKEN:-$("${SCRIPT_DIR}"/get-auth-token.sh)}

# We want slightly different requests depending on if this is the first rack
# being created or not.
#
# If it is the first, we need to specify the name and height of the rack.  If
# it is not the first, we don't want to specify them, and instead use the
# defaults that are calculated on the details of the last created rack.
NUM_RACKS=$("${SCRIPT_DIR}/list-racks.sh" | jq -r length)

if [ "${NUM_RACKS}" == "0" ] ; then
    # If we don't yet have any racks we create a body with the name and U
    # height.
    BODY=$(jq --null-input \
        --arg name "Rack-1" \
        --arg u_height 42 \
        '
{
  "name": $name,
  "u_height": $u_height|tonumber
}
'
)
fi

# Run curl with funky redirection to capture response body and status code.
BODY_FILE=$(mktemp)
HTTP_STATUS=$(
if [ "${NUM_RACKS}" == "0" ] ; then
    curl -s -k \
        -w "%{http_code}" \
        -o >(cat > "${BODY_FILE}") \
        -H 'Content-Type: application/json' \
        -H "Accept: application/json" \
        -H "Authorization: Bearer ${AUTH_TOKEN}" \
        -X POST "${BASE_URL}/racks" \
        -d "${BODY}"
else
    # If we already have some racks defined, we send an empty body to use
    # defaults based on those provided for the last created rack.
    curl -s -k \
        -w "%{http_code}" \
        -o >(cat > "${BODY_FILE}") \
        -H "Accept: application/json" \
        -H "Authorization: Bearer ${AUTH_TOKEN}" \
        -X POST "${BASE_URL}/racks" \
        -d ''
fi
)

if [ "${HTTP_STATUS}" == "200" ] || [ "${HTTP_STATUS}" == "201" ] ; then
    cat "$BODY_FILE"
else
    echo "Rack creation failed" >&2
    cat "$BODY_FILE" >&2
    exit 1
fi
