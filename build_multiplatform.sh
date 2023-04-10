#!/bin/bash

help() {
  echo "Helper script to build single or multiplatform (depending on the input parameter)"
  echo "images for both almalinux and ubuntu distributions."
  echo
  echo "Syntax: $0 [--load|--push]"
  echo "options:"
  echo "load     Builds single platform (of runner's system type) images and loads them into"
  echo "         into local docker registry (they are visible through the 'docker images'"
  echo "         command."
  echo "push     Builds both 'amd64' and 'arm64' architectures images and pushes them to the."
  echo "         dockerhub. Note that in this case one needs to be logged in to"
  echo "         'gerritcodereview' account and images are not visible in the local registry."
  echo
}

DESTINATION=$1

if ! [[ "$DESTINATION" =~ ^(--load|--push)$ ]]; then
  help
  exit
fi

if [[ $DESTINATION == *load ]]; then
  if [[ $(uname -m) == *arm64* ]]; then
    PLATFORMS="linux/arm64"
  else
    PLATFORMS="linux/amd64"
  fi
else
  PLATFORMS="linux/amd64,linux/arm64"
fi

echo "### Building images for $DESTINATION destination and $PLATFORMS platforms"

BUILDER=gerrit-multiplatform-image-builder
DOCKER_USER=gerritcodereview/gerrit

function create_builder() {
  if [[ "$OSTYPE" == "linux"* ]]; then
    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
  fi
  docker buildx create --name $BUILDER --platform "$PLATFORMS" --driver docker-container --use
  docker buildx inspect --bootstrap
}

STATUS="$(docker buildx inspect $BUILDER 2>&1 | grep Status:)"
if [ "$?" -ne "0" ]; then
  set -e
  echo "### Multi-platform builder $BUILDER doesn't exist and will be created."
  create_builder
else
  set -e
  STATUS="${STATUS##* }"
  if [[ $STATUS == *running* ]]; then
    echo "### Multi-platform builder $BUILDER is up and running."
  else
    echo "### Multi-platform builder $BUILDER exists but it doesn't run. It will be re-created."
    docker buildx rm $BUILDER
    create_builder
  fi
fi

VERSION=$(git describe)
VERSION=${VERSION:1}

echo
echo "### Building almalinux multi-platform: [$PLATFORMS] iamges"
(cd almalinux/9 && docker buildx build --platform "$PLATFORMS" --no-cache -t "$DOCKER_USER:${VERSION}-almalinux9" -t "$DOCKER_USER:$VERSION" "$DESTINATION" .)

echo
echo "### Building ubuntu multi-platform: [$PLATFORMS] iamges"
(cd ubuntu/22 && docker buildx build --platform "$PLATFORMS" --no-cache -t "$DOCKER_USER:${VERSION}-ubuntu22" "$DESTINATION" .)

echo
echo "### Removing multi-platform builder"
echo y | docker buildx prune
docker buildx stop $BUILDER
docker buildx rm $BUILDER
