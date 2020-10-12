#!/bin/sh

set -e
env

cat $GITHUB_EVENT_PATH | jq .
RELEASE_ID=$(cat $GITHUB_EVENT_PATH | jq -r .release.id)
RELEASE_TAG_NAME=$(cat $GITHUB_EVENT_PATH | jq -r .release.tag_name)
UPLOAD_URL="https://uploads.github.com/repos/$GITHUB_REPOSITORY/releases/$RELEASE_ID/assets"

GOOSES="linux windows darwin"
GOARCHES="amd64"

for GOOS in $GOOSES; do
  for GOARCH in $GOARCHES; do
    export GOOS
    export GOARCH
    if test $GOOS = "windows"; then
      EXECUTABLE_NAME="$(basename $GITHUB_REPOSITORY).exe"
      ARCHIVE_NAME="${EXECUTABLE_NAME}_${RELEASE_TAG_NAME}_${GOOS}_${GOARCH}.zip"
    else
      EXECUTABLE_NAME=$(basename $GITHUB_REPOSITORY)
      ARCHIVE_NAME="${EXECUTABLE_NAME}_${RELEASE_TAG_NAME}_${GOOS}_${GOARCH}.tar.gz"
    fi
    go build -o $EXECUTABLE_NAME -tags osusergo,netgo
    if test $GOOS = "windows"; then
      zip $ARCHIVE_NAME $EXECUTABLE_NAME
    else
      tar cvfz $ARCHIVE_NAME $EXECUTABLE_NAME
    fi
    CHECKSUM=$(md5sum $ARCHIVE_NAME | cut -d ' ' -f 1)
    if test $GOOS = "windows"; then
      curl \
        -X POST \
        -H "Accept: application/vnd.github.v3+json" \
        --data-binary @$ARCHIVE_NAME \
        -H 'Content-Type: application/zip' \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        "$UPLOAD_URL?name=$ARCHIVE_NAME"
    else
      curl \
        -X POST \
        -H "Accept: application/vnd.github.v3+json" \
        --data-binary @$ARCHIVE_NAME \
        -H 'Content-Type: application/gzip' \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        "$UPLOAD_URL?name=$ARCHIVE_NAME"
    fi
    curl \
      -X POST \
      -H "Accept: application/vnd.github.v3+json" \
      --data $CHECKSUM \
      -H 'Content-Type: text/plain' \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      "$UPLOAD_URL?name=$ARCHIVE_NAME-checksum.txt"
  done
done