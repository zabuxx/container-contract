#!/usr/bin/env bash
#
# Author: Zabuxx - wouter at okalice dev
#
# Usage:
#   containter-contract.sh [CMD]
#
#  CMD is passed to a paritytech/contracts-ci-linux container launched
#  from the current directory.
#
# Example:
#   container-contract.sh cargo +nightly contract build --release
#
# See README.md for more details

#ENGINE=podman
ENGINE=docker

# Exit when run without arguments
(($# > 0)) || exit 1

# agieng-file
# * holds the container name
# * the container keeps running as long as:
#   - this file exists
#   - has a timestamp in the future
AFILE=.container-contract.age-file

# touch $AFILE with date 15 mins from now
function touch_agefile() {
    touch --date '15 mins' $AFILE
}

TMP=`mktemp -t container-cargo.XXXXXX`
trap "rm $TMP*" 0


if [ -f $AFILE ]; then
    # Container running
    touch_agefile
else
    # Container name based on current script PID
    CONTAINER_NAME="cc-$$"
    echo $CONTAINER_NAME > $AFILE
    
    touch_agefile
    # run container in background, keep it running as long as
    # aging-file permits
    $ENGINE run --rm --name $CONTAINER_NAME -v .:/builds  \
         paritytech/contracts-ci-linux  bash -c "
    	    touch $TMP
	    while [ $AFILE -nt $TMP ]; do 
	       sleep 10
	       touch $TMP
	    done
	    rm -f $AFILE " &

    # allow some time to spin up
    sleep 0.2
fi

CONTAINER_NAME=$(<$AFILE)

$ENGINE exec $CONTAINER_NAME $@

touch_agefile
