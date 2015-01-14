#!/usr/bin/env zsh

# Find your Heroku token in ~/.netrc. If it's not there, look at the bottom of
# https://dashboard.heroku.com/account for "API Key".
#
# Let's say your token is abc123. Then run this script like this:
#
# HEROKU_TOKEN=abc123 APP_NAME=my-cool-app ./deploy-a-url-shortener.zsh
#
# It will create an app named $APP_NAME and deploy
# https://github.com/gabebw/crumple (a URL shortener) to it.

TAR_GZ="https://github.com/gabebw/crumple/archive/v1.tar.gz"

if [[ -z "$HEROKU_TOKEN" ]]; then
  echo "Set the HEROKU_TOKEN environment variable."
  exit 64
fi

if [[ -z "$APP_NAME" ]]; then
  echo "Set the APP_NAME environment variable."
  exit 64
fi

function hcurl(){
  curl -s -n "$@" \
    -H "Accept: application/vnd.heroku+json; version=3" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $HEROKU_TOKEN" | jq .
}

# Create an app
create_app(){
  hcurl -X POST https://api.heroku.com/apps \
    -d '{
      "name": "'"$APP_NAME"'",
      "region": "us",
      "stack": "cedar"
    }'
}

# Deploy to that app
deploy_to_app(){
  hcurl -X POST "https://api.heroku.com/apps/$APP_NAME/builds" \
    -d '{"source_blob":{"url":"'"$TAR_GZ"'", "version": "tag-v1" }}' \
}

# Check on the app's first build, because it needs to build before we can run
# `rake db:migrate` or set environment variables
check_initial_build_status() {
  hcurl "https://api.heroku.com/apps/$APP_NAME/builds" | jq ".[0].status"
}

create_one_off_dyno() {
  the_command="$1"
  hcurl -X POST "https://api.heroku.com/apps/$APP_NAME/dynos" \
  -d '{
    "attach": false,
    "command": "'"$the_command"'",
    "env": {
      "COLUMNS": "80",
      "LINES": "24"
    },
    "size": "1X"
  }'
}

set_config_variable() {
  key="$1"
  value="$2"

  hcurl -X PATCH "https://api.heroku.com/apps/$APP_NAME/config-vars" \
    -d "{ \"$key\": \"$value\" }"
}

ensure_app_is_built(){
  echo "Waiting for app to build, might take a while..."

  initial_build_status=$(check_initial_build_status)

  while [[ "$initial_build_status" != '"succeeded"' ]]; do
    sleep 10
    initial_build_status=$(check_initial_build_status)
    echo "Status: $initial_build_status"
  done
}

create_app > /dev/null && \
  deploy_to_app > /dev/null

ensure_app_is_built

set_config_variable "RAILS_SERVE_STATIC_FILES" "true"

create_one_off_dyno "rake db:migrate"

echo "It worked (probably)! Wait a minute or two, then check out http://$APP_NAME.herokuapp.com"
