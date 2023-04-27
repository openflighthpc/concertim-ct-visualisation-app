#!/bin/bash

set -e
set -o pipefail
# set -x

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Use the specified AUTH_TOKEN or generate one.  If AUTH_TOKEN is being
# generated LOGIN and PASSWORD environment variables must be set.
#
# Either way, export it so that it is reused by the other scripts.
AUTH_TOKEN=${AUTH_TOKEN:-$("${SCRIPT_DIR}"/get-auth-token.sh)}
export AUTH_TOKEN

# Create a rack and capture its ID.
OUTPUT=$("${SCRIPT_DIR}/create-rack.sh" "$@")
if [ $? -ne 0 ] ; then
    # Errors will have been sent to stderr.
    exit
fi
RACK_ID=$(echo "${OUTPUT}" | jq -r .id)
RACK_NAME=$(echo "${OUTPUT}" | jq -r .name)
echo "Created empty rack ${RACK_NAME}" >&2
"${SCRIPT_DIR}/show-rack.sh" "${RACK_ID}"
echo

# Prefix nodes in the first rack with `1`, nodes in the second rack with `2`
# etc..
NUM_RACKS=$("${SCRIPT_DIR}/list-racks.sh" | jq 'length')
NAME_PREFIX=$( echo "${RACK_NAME}" | tr -dc 0-9 )

# Create a badly named and located device in that empty rack.
LARGE_TEMPLATE_ID=4
OUTPUT=$("${SCRIPT_DIR}/create-device.sh" comp-${NAME_PREFIX}01 "${RACK_ID}" f 11 "${LARGE_TEMPLATE_ID}")
if [ $? -ne 0 ] ; then
    # Errors will have been sent to stderr.
    exit
fi
DEVICE_ID=$(echo "${OUTPUT}" | jq -r .id)
echo "Added badly named and located device to rack" >&2
"${SCRIPT_DIR}/show-rack.sh" "${RACK_ID}"
echo

# Correct the name of the device.
OUTPUT=$("${SCRIPT_DIR}/update-device.sh" "${DEVICE_ID}" comp${NAME_PREFIX}01)
if [ $? -ne 0 ] ; then
    # Errors will have been sent to stderr.
    exit
fi
echo "Renamed device" >&2
"${SCRIPT_DIR}/show-device.sh" "${DEVICE_ID}"
echo

# Correct the location of the device.
OUTPUT=$("${SCRIPT_DIR}/move-device.sh" "${DEVICE_ID}" "${RACK_ID}" f 1)
if [ $? -ne 0 ] ; then
    # Errors will have been sent to stderr.
    exit
fi
echo "Moved device" >&2
"${SCRIPT_DIR}/show-device.sh" "${DEVICE_ID}"
echo

./populate-rack.sh ${RACK_ID} 4 39 comp${NAME_PREFIX}02

"${SCRIPT_DIR}/show-rack.sh" "${RACK_ID}"
echo
