#!/usr/bin/env bash
set -ev

if ! [ -n ${TRAVIS_TAG} ]; then
    docker login -u="${DOCKER_USERNAME}" -p="${DOCKER_PASSWORD}"
    TAG=${TRAVIS_TAG#"v"}
    for name in ${IMAGE_NAME}:latest ${IMAGE_NAME}:${TAG} ${IMAGE_NAME}:${TAG:0:1} ${IMAGE_NAME}:${TAG:0:3} ${IMAGE_NAME}:${TAG:0:5}; do
        docker tag ${name} && docker push ${name}
    done
fi
