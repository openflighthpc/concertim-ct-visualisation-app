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


####################################
# Create a rack
####################################

# We want slightly different requests depending on if this is the first rack
# being created or not.
#
# If it is the first, we need to specify the name and height of the rack.  If
# it is not the first, we don't want to specify them, and instead use the
# defaults that are calculated on the details of the last created rack.
NUM_RACKS=$(
curl -s -k \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer ${AUTH_TOKEN}" \
    -X GET "${BASE_URL}/racks" \
    | jq -r length
)

if [ "${NUM_RACKS}" == "0" ] ; then
    # If we don't yet have any racks we create a body with the name,
    # description and U height.  The name and description are both required.
    BODY=$(jq --null-input \
        --arg name "Rack-1" \
        --arg description "A rack" \
        --arg u_height 42 \
        '{"name": $name, "description": $description, "u_height": $u_height|tonumber}'
    )
    EXTRA_ARGS="-H 'Content-Type: application/json' -d \"${BODY}\""
else
    # If we already have some racks defined, we send an empty body to use
    # defaults based on those provided for the last created rack.
    # BODY=""
    # EXTRA_ARGS="-d \"${BODY}\""
    EXTRA_ARGS="-d ''"
fi

# Run curl with funky redirection to capture response body and status code.
exec 3>&1 
TEMP_FILE=$(mktemp)
HTTP_STATUS=$(
curl -s -k \
    -w "%{http_code}" \
    -o >(cat > "${TEMP_FILE}") \
    -H "Authorization: Bearer ${AUTH_TOKEN}" \
    -X POST "${BASE_URL}/racks" \
    ${EXTRA_ARGS}
)

if [ "${HTTP_STATUS}" == "200" ] || [ "${HTTP_STATUS}" == "201" ] ; then
    cat "$TEMP_FILE"
else
    echo "Rack creation failed" >&2
    cat "$TEMP_FILE" >&2
    exit 1
fi
