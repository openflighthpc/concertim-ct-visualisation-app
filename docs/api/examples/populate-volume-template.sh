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

BODY=$(jq --null-input '
{
    "template": {
        "name": "volume",
        "description": "Volume",
        "height": 2,
        "tag": "volume",
        "images": {
          "front": "disk_front_2u.png",
          "rear": "generic_rear_2u.png"
        },
        "rackable": "rackable"
    }
}
' \
  | jq '{template: .template | with_entries(select(.value != ""))}'
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
    -X POST "${BASE_URL}/templates" \
    -d "${BODY}"
)

if [ "${HTTP_STATUS}" == "200" ] || [ "${HTTP_STATUS}" == "201" ] ; then
    cat "$BODY_FILE"
else
    echo "Template creation failed" >&2
    cat "$BODY_FILE" >&2
    exit 1
fi
