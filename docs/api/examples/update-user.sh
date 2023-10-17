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
CLOUD_USER_ID=${2}
PROJECT_ID=${3}
BILLING_ACCT_ID=${4}

BODY=$(jq --null-input \
    --arg cloud_user_id "${CLOUD_USER_ID}" \
    --arg project_id "${PROJECT_ID}" \
    --arg billing_acct_id "${BILLING_ACCT_ID}" \
    '
{
    "user": {
        "cloud_user_id": $cloud_user_id,
        "project_id": $project_id,
        "billing_acct_id": $billing_acct_id
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
