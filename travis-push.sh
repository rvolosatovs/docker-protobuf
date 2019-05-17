#!/usr/bin/env bash
set -xe

function tag_and_push {
    docker tag "${IMAGE_NAME}:latest" "${IMAGE_NAME}:${1}" && docker push "${IMAGE_NAME}:${1}"
}
    

echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
if [ "${TRAVIS_TAG}" ]; then
    TAG=${TRAVIS_TAG#"v"}
    if [[ ${TAG} =~ 3\.[0-9]+\.[0-9]+$ ]]; then 
        docker push "${IMAGE_NAME}:latest"
        tag_and_push "${TAG}"
        tag_and_push "${TAG%.*}"
        tag_and_push "${TAG%.*.*}"; 
    else
        tag_and_push "${TAG}"
    fi
elif [ "${TRAVIS_BRANCH}" = "master" ]; then
    tag_and_push "nightly"
else 
    tag_and_push "development"
fi
