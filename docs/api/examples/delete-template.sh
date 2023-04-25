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

TEMPLATE_ID="${1}"
RECURSE="${2}"

if [ "${RECURSE}" == "recurse" ] ; then
  PARAMS="?recurse=true"
else
  PARAMS=""
fi

# Delete the template.
#
# If the `recurse=true` get parameter is not provided, the template will only
# be deleted if it doesn't have any associated devices. If the `recurse=true`
# get parameter is provided, any devices created from the template will be
# deleted too.
curl -s -k \
  -H 'Accept: application/json' \
  -H "Authorization: Bearer ${AUTH_TOKEN}" \
  -X DELETE "${BASE_URL}/templates/${TEMPLATE_ID}${PARAMS}"
