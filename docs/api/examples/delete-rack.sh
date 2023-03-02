#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# The base URL against which relative URLs are constructed.
# BASE_URL="https://localhost:9444/--/api/v1"
BASE_URL="https://command.concertim.alces-flight.com/--/api/v1"

# Use the specified AUTH_TOKEN or generate one.  If AUTH_TOKEN is being
# generated LOGIN and PASSWORD environment variables must be set.
AUTH_TOKEN=${AUTH_TOKEN:-$("${SCRIPT_DIR}"/get-auth-token.sh)}

RACK_ID="${1}"

# Delete the rack and all of its devices.
# If the `recurse=true` get parameter is not provided, only empty racks will be
# deleted.
curl -s -k \
  -H 'Accept: application/json' \
  -H "Authorization: Bearer ${AUTH_TOKEN}" \
  -X DELETE "${BASE_URL}/racks/${RACK_ID}?recurse=true"
