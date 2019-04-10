#!/bin/bash

ENVIRONMENT=$1

if [[ -z "$ENVIRONMENT" ]]; then
  >&2 echo "ERROR please define ENVIRONMENT"
  exit 1
fi

oc() { 
    bin/oc_wrapper.sh $@
    if [[ "$?" != 0 ]]; then
        >&2 echo "ERROR oc wrapper returned none zero status"
    fi
}

if ! oc project $ENVIRONMENT 1>/dev/null 2>/dev/null; then
  >&2 echo "ERROR could not change project to $ENVIRONMENT"
  exit 2
fi

MESSAGE=$(
    echo 'Environment uniqkey-live has been updated. Here are the running app versions:'
    echo '```'
    oc get dc | gawk 'match($NF, /config,image\((.*)\)/, m) {print m[1]}' | sort
    echo '\n```'
)