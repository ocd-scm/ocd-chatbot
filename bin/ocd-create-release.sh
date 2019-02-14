#!/bin/bash
set +x

APP=echo( $1 |  tr '-' '_')

if [[ -z "$APP" ]]; then
  >&2 echo "ERROR please define APP"
  exit 1
fi

# https://unix.stackexchange.com/a/251896/72040
if [[ -z "${!APP}" ]]; then
  >&2 echo "ERROR no git url defind with key ${APP}. Note: use underscores not hyphens."
  exit 2
fi

SHA=$2

if [[ -z "$SHA" ]]; then
  >&2 echo "ERROR please define SHA"
  exit 3
fi

TAG=$3

if [[ -z "$TAG" ]]; then
  TAG=$(printf "v%s" $(date +"%Y%m%d_%H%M%S") )
  echo "creating tag $TAG"
fi

if [ -z "$GITHUB_USER" ]; then
  echo "Please define GITHUB_USER so that we can push a release to github"
  exit 4
fi

# https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/
if [ -z "$GITHUB_OAUTH_TOKEN" ]; then
  echo "Please define GITHUB_OAUTH_TOKEN so that we can push a release to github"
  exit 5
fi

KEY=$APP

source $APP_ROOT/src/bin/ocd-checkout.sh

if ! hub release create -m "ocd-slackbot release $TAG" --commitish=$SHA $TAG; then
  echo "ERROR in folder $PWD could hub release create -m 'ocd-slackbot release $TAG'' --commitish=$SHA $TAG"
fi