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

REGEX="s/OCD_TAG=.*/OCD_TAG=$OCD_TAG/1"

if [[ -z "$PATH" ]]; then
  >&2 echo "ERROR please define PATH"
  exit 3
fi

VALUE=$4

if [[ -z "$VALUE" ]]; then
  >&2 echo "ERROR please define VALUE"
  exit 4
fi

echo "$0 $APP $FILE $PATH $VALUE"

hub() { 
    $APP_ROOT/hub "$@" 
}

#http://mikefarah.github.io/yq/write/#updating-files-in-place
#yq w -i sample.yaml b.c cat
#yq w -i $FILE $PATH $VALUE

sed -i .bak "s/OCD_TAG=.*/OCD_TAG=$OCD_TAG/1" ocd-slackbot/envvars

echo hub release create -m "ocd-slackbot release" -t $SHA $TAG
#hub release create -m "ocd-slackbot release" -t $SHA $TAG