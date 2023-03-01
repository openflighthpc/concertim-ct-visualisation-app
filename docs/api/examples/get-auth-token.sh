#!/bin/bash

set -e
set -o pipefail
# set -x

# The base URL against which relative URLs are constructed.
BASE_URL="https://localhost:9444/--/"
# BASE_URL="https://command.concertim.alces-flight.com/mrd"

# Currently the API is not authenticated.  When authentication is added, it
# will be via a bearer token that will be gained via a HTTP API request.
# AUTH_TOKEN=$(curl -s -k -X POST "${BASE_URL}/sessions" -d '{}' | jq -r .token)
AUTH_TOKEN=""

LOGIN=${LOGIN:-$1}
PASSWORD=${PASSWORD:-$2}

BODY=$(jq --null-input \
    --arg login "${LOGIN}" \
    --arg password "${PASSWORD}" \
    '
{
    "user": {
        "login": $login,
        "password": $password,
    }
}
'
)

# Run curl with funky redirection to capture the headers, response body and status code.
HEADERS_FILE=$(mktemp)
BODY_FILE=$(mktemp)
HTTP_STATUS=$(
curl -s -k \
    -D "${HEADERS_FILE}" \
    -w "%{http_code}" \
    -o >(cat > "${BODY_FILE}") \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    -X POST "${BASE_URL}/users/sign_in.json" \
    -d "${BODY}"
)

if [ "${HTTP_STATUS}" == "200" ] || [ "${HTTP_STATUS}" == "201" ] ; then
    cat "$HEADERS_FILE" | grep '^Authorization: ' | cut -d ' ' -f 3
else
    echo "Login failed" >&2
    cat "$BODY_FILE" >&2
    exit 1
fi
