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
SIMPLE_STATUS=${2}
DETAILED_STATUS=${3}

# The metadata below contains a hardcoded value for `metadata.status`.
# Currently, there is a limitation that all metadata fields must be sent on
# every metadata update.  For the purpose of this example, let's pretend that
# the UUID is correct and has been fetched previously.
#
# The `metadata.status` value is sent as a single string value.  It can be
# set in any way that the concertim-openstack-service finds easiest.  A single
# string value, an array, or a string that is teated as a comma separated list.
# The only consumer of this value is `concertim-openstack-service` itself.

BODY=$(jq --null-input \
    --arg status "${SIMPLE_STATUS}" \
    --arg detailed_status "${DETAILED_STATUS}" \
    '
{
    "rack": {
        "status": $status,
        "metadata": {
          "status": $detailed_status,
          "openstack_stack_id": "92927d62-ebcf-4faf-a8ab-4068ca3911f3"
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
