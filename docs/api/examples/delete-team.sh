#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# The base URL against which relative URLs are constructed.
CONCERTIM_HOST=${CONCERTIM_HOST:-command.concertim.alces-flight.com}
BASE_URL="https://${CONCERTIM_HOST}/api/v1"

# Use the specified AUTH_TOKEN or generate one.  If AUTH_TOKEN is being
# generated LOGIN and PASSWORD environment variables must be set.
AUTH_TOKEN=${AUTH_TOKEN:-$("${SCRIPT_DIR}"/get-auth-token.sh)}

TEAM_ID="${1}"
RECURSE="${2}"

if [ "${RECURSE}" == "recurse" ] ; then
  PARAMS="?recurse=true"
else
  PARAMS=""
fi

# Delete the team.
#
# If the `recurse=true` get parameter is not provided, the team will only be
# deleted if it currently has no racks or devices. If the `recurse=true` get
# parameter is provided, all of the team's racks and devices will be deleted
# along with the team.
curl -s -k \
  -H 'Accept: application/json' \
  -H "Authorization: Bearer ${AUTH_TOKEN}" \
  -X DELETE "${BASE_URL}/teams/${TEAM_ID}${PARAMS}"
