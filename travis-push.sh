#!/usr/bin/env bash
set -xe

if [ ${TRAVIS_TAG} ]; then
    docker login -u="${DOCKER_USERNAME}" -p="${DOCKER_PASSWORD}"
    TAG=${TRAVIS_TAG#"v"}
    [[ ${TAG} == 3* ]] && docker push ${IMAGE_NAME}:latest
    for name in ${IMAGE_NAME}:${TAG} ${IMAGE_NAME}:${TAG%-*} ${IMAGE_NAME}:${TAG%.*-*} ${IMAGE_NAME}:${TAG%.*.*-*}; do
        docker tag ${IMAGE_NAME}:latest ${name} && docker push ${name}
    done
fi
