#!/bin/bash
set +x

APP=$1

if [[ -z "$APP" ]]; then
  >&2 echo "ERROR please define APP"
  exit 1
fi

# https://unix.stackexchange.com/a/251896/72040
if [[ -z "${!APP}" ]]; then
  >&2 echo "ERROR no git url defind with key ${APP}"
  exit 3
fi

# we assume we have an env var $APP defined as key with value of git url
ENV_GIT_URL=$(printf "%s" "${!APP}" )

echo "ENV_GIT_URL=${ENV_GIT_URL}"

# we are running in a random assigned uid with no matching /etc/password
# so we sythesis an entry as per https://docs.openshift.com/enterprise/3.1/creating_images/guidelines.html#openshift-enterprise-specific-guidelines
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
cat /etc/passwd > /tmp/passwd
echo ocd:x:${USER_ID}:${GROUP_ID}:OCD Env Webhookr:${HOME}:/bin/bash > ./passwd.template
envsubst < ./passwd.template >> /tmp/passwd
export LD_PRELOAD=libnss_wrapper.so
export NSS_WRAPPER_PASSWD=/tmp/passwd
export NSS_WRAPPER_GROUP=/etc/group

cd $APP_ROOT

# checkout the code
if [ ! -d $APP ]; then
  git clone --depth 1 --single-branch $ENV_GIT_URL $APP
fi

cd $APP

git pull -X theirs

FILE=ocd-slackbot/envvars

if [[ -z "$FILE" ]]; then
  >&2 echo "ERROR please define FILE"
  exit 2
fi

echo "FILE=$FILE"

REGEX="s/OCD_TAG=.*/OCD_TAG=$OCD_TAG/1"

if [[ -z "$REGEX" ]]; then
  >&2 echo "ERROR please define REGEX"
  exit 3
fi

echo "REGEX=$REGEX"

OCD_TAG=$4

if [[ -z "$OCD_TAG" ]]; then
  >&2 echo "ERROR please define OCD_TAG"
  exit 4
fi

echo "OCD_TAG=$OCD_TAG"

echo "$0 $APP $FILE $REGEX $OCD_TAG"

hub() { 
    $APP_ROOT/hub "$@" 
}

