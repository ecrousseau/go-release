#!/bin/sh

set -e

EXECUTABLE_NAME=$(basename $GITHUB_REPOSITORY)
RELEASE_ID=$(cat $GITHUB_EVENT_PATH | jq .release.id)
RELEASE_TAG_NAME=$(cat $GITHUB_EVENT_PATH | jq .release.tag_name)
UPLOAD_URL="https://uploads.github.com/repos/$GITHUB_REPOSITORY/releases/$RELEASE_ID/assets"

GOOSES="linux windows darwin"
GOARCHES="amd64"

cd $GITHUB_WORKSPACE
for GOOS in $GOOSES; do
  for GOARCH in $GOARCHES; do
    export GOOS
    export GOARCH
    if [[ $GOOS == "windows" ]]; then $EXECUTABLE_NAME="$EXECUTABLE_NAME.exe"; fi
    go get
    go build -o $EXECUTABLE_NAME -tags osusergo,netgo
    NAME="${EXECUTABLE_NAME}_${RELEASE_TAG_NAME}_${GOOS}_${GOARCH}"
    tar cvfz $NAME.tar.gz $EXECUTABLE_NAME
    CHECKSUM=$(md5sum $NAME.tar.gz | cut -d ' ' -f 1)
    curl \
      -X POST \
      --data-binary @$NAME.tar.gz \
      -H 'Content-Type: application/gzip' \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      "$UPLOAD_URL?name=$NAME.tar.gz"
    curl \
      -X POST \
      --data $CHECKSUM \
      -H 'Content-Type: text/plain' \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      "$UPLOAD_URL?name=${NAME}_checksum.txt"
  done
done