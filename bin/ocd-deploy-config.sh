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

# we lookup the git url by "$app_$env"
KEY=$(printf "%s_%s" "$APP" "$ENVIRONMENT")

# this prints the value assocaited with the env var $KEY
ENV_GIT_URL=$(printf "%s" "${!KEY}" )

if [ -z "$ENV_GIT_URL" ]; then
  >&2 echo "ERROR could not resolve ENV_GIT_URL for key $KEY" 
  exit 6
fi

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

# checkout the code into folder $app_$env
if [ ! -d $KEY ]; then
  git clone $ENV_GIT_URL $KEY 1>/dev/null
fi

cd $KEY

git checkout master 2>/dev/null

git pull -X theirs 1>/dev/null

MESSAGE="ocd-slackbot deploy $TAG"

if [ ! -f ./envvars ]; then
  >&2 echo "ERROR no envvars in $(pwd)" 
  exit 7
fi

sed -i "s/^${APP}_version=.*/${APP}_version=${TAG}/g" ./envvars

if [[ "$?" != "0" ]]; then
  >&2 echo "ERROR unable to replace ${APP}_version in $(pwd)/envvars" 
  exit 8  
fi

git checkout -b "$TAG"
git commit -am "$MESSAGE"

if [[ "$?" == "128" ]]; then
  git config --global user.email "ocd-slackbot@example.com"
  git config --global user.name "OCD SlackBot"
  git config --global push.default matching
  git commit -am "$MESSAGE"
fi

git push origin "$TAG"

hub() { 
    $APP_ROOT/hub "$@" 
}

if [[ ! -f ~/.config/hub ]]; then
  mkdir -p ~/.config
# https://github.com/github/hub/issues/978#issuecomment-131964409
cat >~/.config/hub <<EOL
---
github.com:
- protocol: https
  user: ${GITHUB_USER}
  oauth_token: ${GITHUB_OAUTH_TOKEN}
EOL
fi

hub pull-request -m $MESSAGE