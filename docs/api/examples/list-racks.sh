#!/bin/bash

set -e
set -o pipefail

# The base URL against which relative URLs are constructed.
BASE_URL="https://localhost:9444/--/api/v1"
# BASE_URL="https://command.concertim.alces-flight.com/mrd"

# Currently the API is not authenticated.  When authentication is added, it
# will be via a bearer token that will be gained via a HTTP API request.
# AUTH_TOKEN=$(curl -s -k -X POST "${BASE_URL}/sessions" -d '{}' | jq -r .token)
AUTH_TOKEN=""

curl -s -k \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer ${AUTH_TOKEN}" \
  -X GET "${BASE_URL}/racks"
