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
USER_COST=${2}
BILLING_PERIOD_START=${3}
BILLING_PERIOD_END=${4}
CREDITS=${5}

BODY=$(jq --null-input \
    --arg cost "${USER_COST}" \
    --arg billing_period_start "${BILLING_PERIOD_START}" \
    --arg billing_period_end "${BILLING_PERIOD_END}" \
    --arg credits "${CREDITS}" \
    '
      {
        "user": {
          "cost": $cost, "billing_period_start": $billing_period_start, "billing_period_end": $billing_period_end,
          "credits": $credits
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
    -X PATCH "${BASE_URL}/users/${USER_ID}" \
    -d "${BODY}"
)

if [ "${HTTP_STATUS}" == "200" ] ; then
    cat "$BODY_FILE"
else
    echo "User update failed" >&2
    cat "$BODY_FILE" >&2
    exit 1
fi
