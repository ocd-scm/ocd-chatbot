#!/bin/bash

APP=$1

if [[ -z "$APP" ]]; then
  >&2 echo "ERROR please define APP"
  exit 1
fi

# https://unix.stackexchange.com/a/251896/72040
if [[ -z "${!APP}" ]]; then
  >&2 echo "ERROR no git url defind with key ${APP}"
  exit 2
fi

TAG=$2

if [[ -z "$TAG" ]]; then
  TAG=$(printf "v%s" $(date +"%Y_%m_%d_%H_%M_%S") )
  echo "creating tag $TAG"
fi

ENVIRONMENT=$3

if [[ -z "$ENVIRONMENT" ]]; then
  >&2 echo "ERROR please define ENVIRONMENT"
  exit 1
fi

if [ -z "$GITHUB_USER" ]; then
  echo "Please define GITHUB_USER so that we can push a release to github"
  exit 4
fi

# https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/
if [ -z "$GITHUB_OAUTH_TOKEN" ]; then
  echo "Please define GITHUB_OAUTH_TOKEN so that we can make a pull request"
  exit 5
fi

KEY=$(printf "%s_%s" "$APP" "$ENVIRONMENT")		

source $APP_ROOT/src/bin/ocd-checkout.sh

MESSAGE="ocd-slackbot deploy $TAG"

if [ ! -f ./envvars ]; then
  >&2 echo "ERROR no envvars in $(pwd)" 
  exit 10
fi

sed -i "s/^${APP}_version=.*/${APP}_version=${TAG}/g" ./envvars

if [[ "$?" != "0" ]]; then
  >&2 echo "ERROR unable to replace ${APP}_version in $(pwd)/envvars" 
  exit 11
fi
 
git checkout -b "$TAG"
git commit -am "$MESSAGE"
git push origin "$TAG" 1>/dev/null

hub pull-request -m "$MESSAGE"