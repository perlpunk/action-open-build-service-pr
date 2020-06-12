#!/bin/bash

check-args() {
    argtype=$1
    shift
    for i in $@; do
        local value="${!i}"
        if [[ -z "$value" ]]; then
            echo "$argtype '$i' not set" >&2
            exit 1
        fi
    done
}

write-oscrc() {
    echo "[general]
apiurl = $apiurl
[$apiurl]
user = $OSCLOGIN
pass = $OSCPASS" > ~/.oscrc
}

post-status() {
    local state="$1" url="$2" desc="$3"
    data='{"context":"OBS","target_url":"'"$url"'","state":"'"$state"'","description":"'"$desc"'"}'
    echo "Posting status $data"

    curl --show-error --silent --request POST \
      "https://api.github.com/repos/$GITHUB_REPOSITORY/statuses/$GITHUB_SHA" \
      --header "Authorization: token $GITHUB_TOKEN" \
      --data "$data" \
      >/dev/null
}
