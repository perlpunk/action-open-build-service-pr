#!/bin/bash

set -e
source /tools/utils.sh

apiurl="$1"
project="$2"
package="$3"
branchprefix="$4"
timeout="$5"
sleeptime="$6"
ignore_repos="$7"
echo "args: $@"

giturl="git://github.com/$GITHUB_REPOSITORY.git"

check-args Input apiurl project package branchprefix
check-args Variable OSCLOGIN OSCPASS GITHUB_TOKEN

echo "showing \$GITHUB_EVENT_PATH=$GITHUB_EVENT_PATH"
cat $GITHUB_EVENT_PATH || true
if [ "$GITHUB_EVENT_NAME" == "pull_request" ]; then
    GITHUB_SHA=$(cat $GITHUB_EVENT_PATH | jq -r .pull_request.head.sha)
fi

osc --version

write-oscrc

weburl="$(osc api /configuration)"
if [[ $weburl =~ \<obs_url\>([^\<]+) ]]; then
    weburl="${BASH_REMATCH[1]}"
fi
weburl="$weburl/package/show/"

branchprefix="${branchprefix/\$USER/$OSCLOGIN}"
suffix="${GITHUB_REF/refs\//}"
if [[ "$GITHUB_EVENT_NAME" == push ]]; then
    suffix="branch-${suffix/heads\//}"
elif [[ "$GITHUB_EVENT_NAME" == pull_request ]]; then
    suffix="pr-${suffix/pull\//}"
fi
# replace slashes and colons with -
suffix="${suffix//\//-}"
suffix="${suffix//:/-}"

branchproject="$branchprefix:$project-$suffix"
branch="$branchproject/$package"
details_url="$weburl$branch"


projects=($(osc list "$branchproject" || true))
echo "projects: ($projects) num: ${#projects[@]}"

# Check if already branched
if [[ "${#projects[@]}" -eq 0 ]]; then
    osc branch "$project" "$package" "$branchproject" "$package"
fi

laststatus=pending
post-status pending "$details_url" "$laststatus"

set -x
osc checkout "$branch"
cd "$branchproject/$package"

if [[ -e _service ]]; then
    /tools/update-service-file _service "$giturl" "$GITHUB_SHA"
fi

osc diff
osc commit -m "Commit $giturl $GITHUB_SHA"

starttime=$(date +%s)

set +x
sleep "$sleeptime";
while true; do
    now=$(date +%s)
    duration=$(( $now - $starttime ))
    duration_string="$((duration / 60 ))m$((duration % 60))s"
    if (( $duration > $timeout )); then
        post-status pending "$details_url" "$duration_string Timeout $laststatus"
        echo "Timeout ($timeout)!" >&2
        exit 1
    fi

    osc api "/build/$branchproject/_result" > /tmp/buildstatus.xml

    set +e # expected failure
    buildstatus=$(/tools/buildstatus /tmp/buildstatus.xml \
      "$branchproject" "$package" "$ignore_repos")
    rc=$?
    set -e
    echo "buildstatus: $buildstatus"

    if [[ $rc -eq 0 ]]; then
        post-status success "$details_url" "$duration_string $buildstatus"
        break
    fi
    if [[ $rc -eq 2 ]]; then
        post-status failure "$details_url" "$duration_string $buildstatus"
        break
    fi
    if [[ "$buildstatus" != "$laststatus" ]]; then
        post-status pending "$details_url" "$buildstatus"
    fi
    laststatus="$buildstatus"
    sleep "$sleeptime";
done

echo "::set-output name=branch::$branch"

