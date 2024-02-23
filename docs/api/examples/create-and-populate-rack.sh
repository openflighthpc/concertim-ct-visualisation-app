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
RACK_HEIGHT=$(echo "${OUTPUT}" | jq -r .u_height)
echo "Created empty rack ${RACK_NAME}" >&2
"${SCRIPT_DIR}/show-rack.sh" "${RACK_ID}"
echo

# Create a badly named and located device in that empty rack.
LARGEST_TEMPLATE=$( "${SCRIPT_DIR}/list-templates.sh" | jq "sort_by(.height) | reverse | .[0]" )
TEMPLATE_ID=$(echo "${LARGEST_TEMPLATE}" | jq -r .id)
TEMPLATE_HEIGHT=$(echo "${LARGEST_TEMPLATE}" | jq -r .height)
START_U=$(( ${RACK_HEIGHT} - ${TEMPLATE_HEIGHT} + 1 ))
OUTPUT=$("${SCRIPT_DIR}/create-device.sh" comp-101 "${RACK_ID}" f ${START_U} "${TEMPLATE_ID}")
if [ $? -ne 0 ] ; then
    # Errors will have been sent to stderr.
    exit
fi
DEVICE_ID=$(echo "${OUTPUT}" | jq -r .id)
echo "Added badly named and located device to rack" >&2
"${SCRIPT_DIR}/show-rack.sh" "${RACK_ID}"
echo

# Correct the name of the device.
OUTPUT=$("${SCRIPT_DIR}/update-device.sh" "${DEVICE_ID}" comp101)
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

OUTPUT=$("${SCRIPT_DIR}/create-network.sh" net-1 "${RACK_ID}" f "$RACK_HEIGHT")
if [ $? -ne 0 ] ; then
    # Errors will have been sent to stderr.
    exit
fi
echo "Created network device"

# Leave some space at the top to allow dragging devices around the IRV.
START_U=$(( ${TEMPLATE_HEIGHT} + 1 ))
END_U=$(( $RACK_HEIGHT - 4 ))
"${SCRIPT_DIR}/populate-rack.sh" ${RACK_ID} ${START_U} ${END_U} comp102

"${SCRIPT_DIR}/show-rack.sh" "${RACK_ID}"
echo
