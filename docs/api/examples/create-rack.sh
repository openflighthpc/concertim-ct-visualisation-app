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

USER_ID=${1}
NAME=${2}
U_HEIGHT=${3}

# Here lies complex JSON documentation creation. The complications arise due to
# the following:
#
# * NAME is optional.
# * U_HEIGHT is optional.
# * USER_ID is mandatory if the rack is being created for an admin user.
#   Otherwise it should not be provided and will be ignored if it is.
#
# To achieve this, we use jq to construct a JSON document, such as
#
# ```
# {"rack": {"name": "", "u_height": 42, "user_id": "3"}}
# ```
#
# Then we pipe that document to jq passing a funky script which dives into the
# `rack` parameter and removes any blank entries.  For the above example the
# resulting document would be:
#
# ```
# {"rack": {"u_height": 42, "user_id": "3"}}
# ```
#
# The metadata below is hardcoded but it could be any valid JSON document.
BODY=$( jq --null-input  \
  --arg name "${NAME}" \
  --arg user_id "${USER_ID}" \
  --arg u_height "${U_HEIGHT}" \
  '
{
  "rack": {
    "name": $name,
    "user_id": $user_id,
    "u_height": $u_height|(try tonumber catch ""),
    "status": "IN_PROGRESS",
    "metadata": {
      "status": "IN_PROGRESS",
      "stack_id": "92927d62-ebcf-4faf-a8ab-4068ca3911f3"
    }
  }
}
' \
  | jq '{rack: .rack | with_entries(select(.value != ""))}'
)

# Run curl with funky redirection to capture response body and status code.
BODY_FILE=$(mktemp)
HTTP_STATUS=$(
  curl -s -k \
      -w "%{http_code}" \
      -o >(cat > "${BODY_FILE}") \
      -H 'Content-Type: application/json' \
      -H "Accept: application/json" \
      -H "Authorization: Bearer ${AUTH_TOKEN}" \
      -X POST "${BASE_URL}/racks" \
      -d "${BODY}"
)

if [ "${HTTP_STATUS}" == "200" ] || [ "${HTTP_STATUS}" == "201" ] ; then
    cat "$BODY_FILE"
else
    echo "Rack creation failed" >&2
    cat "$BODY_FILE" >&2
    exit 1
fi
