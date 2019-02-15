#!/bin/bash

APP=$( echo $1 |  tr '-' '_')

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
  >&2 echo "ERROR please supply TAG."
  exit 3
fi

ENVIRONMENT=$3

if [[ -z "$ENVIRONMENT" ]]; then
  >&2 echo "ERROR please define ENVIRONMENT"
  exit 1
fi

# TODO now that we use ssh can this be deleted
if [ -z "$GITHUB_USER" ]; then
  echo "Please define GITHUB_USER so that we can push a release to github"
  exit 4
fi

# TODO now that we use ssh can this be deleted
# https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/
if [ -z "$GITHUB_OAUTH_TOKEN" ]; then
  echo "Please define GITHUB_OAUTH_TOKEN so that we can make a pull request"
  exit 5
fi

KEY=$( echo $ENVIRONMENT | tr '-' '_' )

source $APP_ROOT/src/bin/ocd-checkout.sh

MESSAGE="ocd-slackbot deploy $TAG"

if [ ! -f ./envvars ]; then
  >&2 echo "ERROR no envvars in $(pwd)" 
  exit 10
fi

if ! sed -i "s/^${APP}_version=.*/${APP}_version=${TAG}/g" ./envvars; then
  >&2 echo "ERROR unable to replace ${APP}_version in $(pwd)/envvars" 
  exit 11
fi
 
if !git checkout -b "$TAG" 2>/dev/null 1>/dev/null; then
  >&2 echo "WARNING failed to create branch $TAG it might exist continuing." 
fi

if ! git commit -am "$MESSAGE" 1>/dev/null; then
  >&2 echo "ERROR failed to commit modification to versions" 
  exit 12
fi

BRANCH=$(date +"%Y%m%d_%H%M%S")

if ! git push origin "$BRANCH" 1>/dev/null; then
  >&2 echo "ERROR failed to git push origin $TAG"
  exit 13
fi

if ! hub pull-request -m "$MESSAGE"; then
  >&2 echo "ERROR failed to hub pull-request -m $MESSAGE on branch $BRANCH"
  exit 14
else
  git branch -d "$BRANCH"
fi
