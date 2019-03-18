#!/usr/bin/env bash
set -xe

if [ ${TRAVIS_TAG} ]; then
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    TAG=${TRAVIS_TAG#"v"}
    if [[ ${TAG} =~ 3\.[0-9]+\.[0-9]+$ ]]; then 
        docker push ${IMAGE_NAME}:latest
        for name in ${IMAGE_NAME}:${TAG} ${IMAGE_NAME}:${TAG%.*} ${IMAGE_NAME}:${TAG%.*.*}; do
            docker tag ${IMAGE_NAME}:latest ${name} && docker push ${name}
        done
    else
        docker tag ${IMAGE_NAME}:latest ${IMAGE_NAME}:${TAG} && docker push ${IMAGE_NAME}:${TAG}
    fi
fi
