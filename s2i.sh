#!/bin/bash
s2i --copy \
    --incremental=true \
    build \
    $(git remote show origin | fgrep 'Fetch URL' | awk '{print $NF}') \
    --ref=master \
    registry.access.redhat.com/rhscl/nodejs-8-rhel7:latest \
    ocd-openshiftbot

docker run -it -p 8080:8080 -e PASSPHRASE=$(<passphrase)  ocd-openshiftbot