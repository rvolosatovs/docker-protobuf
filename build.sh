#!/usr/bin/env sh
set -a

. ./deps.list
docker buildx build \
    $(for v in $(cut -d '=' -f 1 < deps.list); do printf "%s " "--build-arg $v=$(printenv ${v})"; done) \
    ${@} .
