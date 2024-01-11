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

RACK_ID=$1
FIRST_U=$2
END_U=$3
FIRST_DEVICE_NAME=$4
NAME_PREFIX="$(echo "${FIRST_DEVICE_NAME}" | tr -d 0-9)"
FIRST_DEVICE_NUMBER="$(echo "${FIRST_DEVICE_NAME}" | tr -dc 0-9)"

OUTPUT=$("${SCRIPT_DIR}/show-rack.sh" "${RACK_ID}")
if [ $? -ne 0 ] ; then
    # Errors will have been sent to stderr.
    exit
fi
RACK_HEIGHT=$(echo "${OUTPUT}" | jq -r .u_height)
RACK_NAME=$(echo "${OUTPUT}" | jq -r .name)

SMALL_TEMPLATE_ID=$( "${SCRIPT_DIR}/list-templates.sh" | jq -r "sort_by(.height) | .[0] | .id" )
for i in $(seq -w 0 $(( 10#${END_U} - 10#${FIRST_U} )) ) ; do
  # i=$(( 10#${i} - 1 ))
  sleep 0.5
  devnum=$(( 10#${i} + ${FIRST_DEVICE_NUMBER} ))
  name="${NAME_PREFIX}${devnum}"
  start_u=$(( 10#${i} + ${FIRST_U} ))
  OUTPUT=$("${SCRIPT_DIR}/create-device.sh" ${name} "${RACK_ID}" f ${start_u} "${SMALL_TEMPLATE_ID}")
  if [ $? -ne 0 ] ; then
      # Errors will have been sent to stderr.
      exit
  fi
  echo "Added ${name} to rack ${RACK_NAME}" >&2
done

# Update the status for each of the devices in the rack.  Starting from bottom
# to top.
device_ids=$("${SCRIPT_DIR}/show-rack.sh" "${RACK_ID}" | jq -r '.devices[] | .id ' | tac)
for device_id in ${device_ids} ; do
  sleep 0.5
  "${SCRIPT_DIR}/update-device-status.sh" "${device_id}" ACTIVE Active
done
