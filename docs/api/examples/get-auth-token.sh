#!/bin/bash

set -e
set -o pipefail

# The base URL against which relative URLs are constructed.
# BASE_URL="https://localhost:9444/--/"
BASE_URL="https://command.concertim.alces-flight.com/--/"

LOGIN=${LOGIN:-$1}
PASSWORD=${PASSWORD:-$2}

if [ "${LOGIN}" == "" ] || [ "${PASSWORD}" == "" ] ; then
  echo "Login or password are not given." >&2
  echo "Set the LOGIN and PASSWORD environment variables or provide them as arguments to the $(basename $0) script." >&2
  exit 1
fi

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
    cat "$HEADERS_FILE" | grep '^Authorization: ' | cut -d ' ' -f 3 | tr -d '\r\n'
else
    echo "Login failed" >&2
    cat "$BODY_FILE" >&2
    exit 1
fi
