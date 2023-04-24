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


# Populate default dev templates. All templates portrayed in this script are
# fictitious. No identification with actual OpenStack flavours (active or
# inactive) is intended or should be inferred.
"${SCRIPT_DIR}/create-template.sh" Small "m1.small: 1 VCPU; 2GB RAM; 10GB Disk" 1
if [ $? -ne 0 ] ; then
    # Errors will have been sent to stderr.
    exit
fi
"${SCRIPT_DIR}/create-template.sh" Medium "m1.medium: 2 VCPUs; 3GB RAM; 10GB Disk" 2
if [ $? -ne 0 ] ; then
    # Errors will have been sent to stderr.
    exit
fi
"${SCRIPT_DIR}/create-template.sh" Large "m1.large: 4 VCPUs; 8GB RAM; 10GB Disk" 3
if [ $? -ne 0 ] ; then
    # Errors will have been sent to stderr.
    exit
fi
"${SCRIPT_DIR}/create-template.sh" X-Large "m1.xlarge: 8 VCPUs; 16GB RAM; 30GB Disk" 4
if [ $? -ne 0 ] ; then
    # Errors will have been sent to stderr.
    exit
fi
"${SCRIPT_DIR}/create-template.sh" XX-Large "m1.xxlarge: 16 VCPUs; 32GB RAM; 30GB Disk" 5
if [ $? -ne 0 ] ; then
    # Errors will have been sent to stderr.
    exit
fi
"${SCRIPT_DIR}/create-template.sh" XXX-Large "m1.xxxlarge: 32 VCPUs; 64GB RAM; 30GB Disk" 6
if [ $? -ne 0 ] ; then
    # Errors will have been sent to stderr.
    exit
fi
