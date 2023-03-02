#!/bin/bash

set -e
set -o pipefail

# After using the rack and device API a memcache dance needs to be done.  This
# currently isn't preformed automatically by ct-visualisation-app.  For now,
# running this script will result in the memcache dance being performed.
#
# Once the memcache dance has been performed, metrics can be reliably added to
# devices created via the rack/device API.  Until then, metric addition is
# unreliable.

# The base URL against which relative URLs are constructed.
# BASE_URL="https://localhost:9444/--/api/v1"
BASE_URL="https://command.concertim.alces-flight.com/--/api/v1"

# Use the specified AUTH_TOKEN or generate one.  If AUTH_TOKEN is being
# generated LOGIN and PASSWORD environment variables must be set.
AUTH_TOKEN=${AUTH_TOKEN:-$("${SCRIPT_DIR}"/get-auth-token.sh)}

# Run curl with funky redirection to capture response body and status code.
BODY_FILE=$(mktemp)
HTTP_STATUS=$(
curl -s -k \
    -w "%{http_code}" \
    -o >(cat > "${BODY_FILE}") \
    -H "Accept: application/json" \
    -H "Authorization: Bearer ${AUTH_TOKEN}" \
    -X POST "${BASE_URL}/hacks/memcache-dance"
)

if [ "${HTTP_STATUS}" == "200" ] || [ "${HTTP_STATUS}" == "201" ] ; then
    cat "$BODY_FILE"
else
    echo "Memcache dance failed" >&2
    cat "$BODY_FILE" >&2
    exit 1
fi
