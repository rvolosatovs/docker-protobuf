#!/usr/bin/env bash

set -ex

docker buildx build --platform linux/amd64,linux/arm64 \
$(while IFS= read -r line; do echo "--build-arg $line " | tr -d "\n"; done < <(grep -v '^ *#' < deps.list)) \
${@} .
