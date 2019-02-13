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
  exit 2
fi

SHA=$2

if [[ -z "$SHA" ]]; then
  >&2 echo "ERROR please define SHA"
  exit 3
fi

TAG=$3

if [[ -z "$TAG" ]]; then
  TAG=$(printf "v%s" $(date +"%Y_%m_%d_%H_%M_%S") )
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

# we assume we have an env var $APP defined as key with value of git url
ENV_GIT_URL=$(printf "%s" "${!APP}" )
#echo "ENV_GIT_URL=${ENV_GIT_URL}"

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

# if using git ssh we need different ssh deploy keys for each repo
# https://snipe.net/2013/04/11/multiple-github-deploy-keys-single-server/
if [[ "$ENV_GIT_URL" =~ ^git@.* ]]; then
  if [[ ! -d  ~/.ssh ]]; then
    mkdir -p ~/.ssh
  fi
  if [[ ! -f ~/.ssh/config ]]; then
    touch ~/.ssh/config
  fi
  if ! grep $APP  ~/.ssh/config ; then
    (APP=$APP; cat <<EOF >> ~/.ssh/config
Host repo-$APP github.com
Hostname github.com
IdentityFile /opt/app-root/$APP-deploykey/$APP-deploykey
StrictHostKeyChecking no
EOF
    )
  fi
  ENV_GIT_URL=$(echo $ENV_GIT_URL | sed "s/github.com/repo-$APP/1")
fi

# checkout the code
if [ ! -d $APP ]; then
  if ! git clone --single-branch $ENV_GIT_URL $APP 1>/dev/null 2>/dev/null; then
    echo "ERROR could not  git clone --single-branch $ENV_GIT_URL "
    exit 6
  fi
fi

cd $APP

if ! git pull -X theirs 1>/dev/null 2>/dev/null; then
  echo "ERROR could not git pull -X theirs in $PWD"
  exit 7
fi

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

if ! hub release create -m "ocd-slackbot release $TAG --commitish=$SHA $TAG"; then
  echo "ERROR in folder $PWD could not hub release create -m "ocd-slackbot release $TAG" --commitish=$SHA $TAG"
fi