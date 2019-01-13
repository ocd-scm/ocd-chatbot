#!/bin/bash

APP=$1
SHA=$2
DATE=$(date +"%Y-%m-%d_%H-%M-%S")

sleep 1

echo "I made a release of $1 from $2 with tag $DATE"

#$APP_ROOT/hub --help