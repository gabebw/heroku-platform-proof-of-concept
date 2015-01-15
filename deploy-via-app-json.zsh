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

TAR_GZ_WITH_APP_JSON="https://github.com/gabebw/crumple/tarball/master/"

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

# Create an app from a tar.gz with an app.json file
create_app_from_app_json(){
  hcurl -X POST https://api.heroku.com/app-setups \
    -d '{
      "app": {
        "name": "'"$APP_NAME"'",
        "personal": true
      },
      "source_blob": { "url": "'"$TAR_GZ_WITH_APP_JSON"'" }
    }'
}

check_app_status(){
  app_id="$1"
  hcurl -X GET "https://api.heroku.com/app-setups/$app_id"
}

check_if_app_is_built(){
  local app_setup_id="$1"
  echo "=== Periodically checking for app to build (will take ~4 minutes)"
  echo "=== You can Ctrl-C at any time now"

  if [[ "$app_setup_id" != '"bad_request"' ]]; then
    app_status="pending"
    while [[ "$app_status" != "succeeded" ]]; do
      status_json="$(check_app_status "$app_setup_id")"
      app_status="$(echo "$status_json" | jq .status | sed 's/"//g')"
      echo "Status: $app_status"
      sleep 30
    done
  fi
}

result="$(create_app_from_app_json)"
app_setup_id="$(echo "$result" | jq ".id" | sed 's/"//g')"

echo "$result"
echo

check_if_app_is_built "$app_setup_id"

echo
echo "It worked (probably)! Check out http://$APP_NAME.herokuapp.com"
