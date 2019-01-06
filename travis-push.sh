#!/usr/bin/env bash
set -xe

if [ ${TRAVIS_TAG} ]; then
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    TAG=${TRAVIS_TAG#"v"}
    [[ ${TAG} == 3* ]] && docker push ${IMAGE_NAME}:latest
    for name in ${IMAGE_NAME}:${TAG} ${IMAGE_NAME}:${TAG%-*} ${IMAGE_NAME}:${TAG%.*-*} ${IMAGE_NAME}:${TAG%.*.*-*}; do
        docker tag ${IMAGE_NAME}:latest ${name} && docker push ${name}
    done
fi
