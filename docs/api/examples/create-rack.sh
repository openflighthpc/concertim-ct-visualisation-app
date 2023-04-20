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
U_HEIGHT=${2}

# If a previous rack has been created, both the name and height are optional.
# Here we construct the body based on the given inputs and assume that the user
# has provided sufficient arguments.
BODY=$( jq --null-input  \
  --arg name "${NAME}" \
  --arg u_height "${U_HEIGHT}" \
  '
{
  "name": $name,
  "u_height": $u_height|(try tonumber catch "")
}
' \
  | jq 'with_entries( select( .value != "" ) )'
)

# Run curl with funky redirection to capture response body and status code.
BODY_FILE=$(mktemp)
HTTP_STATUS=$(
if [ "${BODY}" != "{}" ] ; then
    # The user has given at least on of rack name or u height.
    curl -s -k \
        -w "%{http_code}" \
        -o >(cat > "${BODY_FILE}") \
        -H 'Content-Type: application/json' \
        -H "Accept: application/json" \
        -H "Authorization: Bearer ${AUTH_TOKEN}" \
        -X POST "${BASE_URL}/racks" \
        -d "${BODY}"
else
    # The user has not provided either rack name or u height.  We assume that
    # there is a previously created rack that sensible defaults can be taken
    # from.  If not, an error message will be displayed.
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
