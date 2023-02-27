#!/bin/bash

set -e
set -o pipefail
# set -x

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Create a rack and capture its ID.
OUTPUT=$("${SCRIPT_DIR}/create-rack.sh")
if [ $? -ne 0 ] ; then
    # Errors will have been sent to stderr.
    exit
fi
RACK_ID=$(echo "${OUTPUT}" | jq -r .id)
echo "Created empty rack" >&2
"${SCRIPT_DIR}/show-rack.sh" "${RACK_ID}"
echo

# Create a device in that empty rack.
# A real script would need to be more intelligent about name and location.
OUTPUT=$("${SCRIPT_DIR}/create-device.sh" comp-201 "${RACK_ID}" f 1)
if [ $? -ne 0 ] ; then
    # Errors will have been sent to stderr.
    exit
fi
DEVICE_ID=$(echo "${OUTPUT}" | jq -r .id)
echo "Added device to rack" >&2
"${SCRIPT_DIR}/show-rack.sh" "${RACK_ID}"
echo

# Move the device to another U in the same rack.
OUTPUT=$("${SCRIPT_DIR}/move-device.sh" "${DEVICE_ID}" "${RACK_ID}" f 10)
if [ $? -ne 0 ] ; then
    # Errors will have been sent to stderr.
    exit
fi
echo "Moved device" >&2
"${SCRIPT_DIR}/show-device.sh" "${DEVICE_ID}"
echo

# Change the name of the device.
OUTPUT=$("${SCRIPT_DIR}/update-device.sh" "${DEVICE_ID}" comp201)
if [ $? -ne 0 ] ; then
    # Errors will have been sent to stderr.
    exit
fi

echo "Renamed device" >&2
"${SCRIPT_DIR}/show-device.sh" "${DEVICE_ID}"
echo

OUTPUT=$("${SCRIPT_DIR}/create-device.sh" comp202 "${RACK_ID}" f 1)
if [ $? -ne 0 ] ; then
    # Errors will have been sent to stderr.
    exit
fi
echo "Added second device to rack" >&2
"${SCRIPT_DIR}/show-rack.sh" "${RACK_ID}"
echo

# Delete the rack.
OUTPUT=$("${SCRIPT_DIR}/delete-rack.sh" "${RACK_ID}")
if [ $? -ne 0 ] ; then
    # Errors will have been sent to stderr.
    exit
fi
echo "Deleted rack and device" >&2
