#!/bin/bash

# By default it builds single platform images (alamalinux and ubuntu) and loads them into
# local docker (--load is assumed) however one can specify --push and it will build for
# both 'amd64' and 'arm64' architectures and push to the dockerhub.
# Note that in the later case one needs to be loged in to 'gerritcodereview' account.

DESTINATION=$1

if [ -z "$DESTINATION" ]; then
  DESTINATION="--load"
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

echo "### Building images for $DESTINATION destination and $PLATFORMS"

BUILDER=gerrit-multiplatform-image-builder
DOCKER_USER=geminicaprograms/gerrit

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

echo
echo "### Building almalinux multi-platform: [$PLATFORMS] iamges"
$(cd almalinux/8 && docker buildx build --platform "$PLATFORMS" --no-cache -t $DOCKER_USER:$(git describe)-almalinux8 -t $DOCKER_USER:$(git describe) $DESTINATION .)

echo
echo "### Building ubuntu multi-platform: [$PLATFORMS] iamges"
$(cd ubuntu/20 && docker buildx build --platform "$PLATFORMS" --no-cache -t $DOCKER_USER:$(git describe)-ubuntu20 $DESTINATION .)

echo
echo "### Removing multi-platform builder"
echo y | docker buildx prune
docker buildx stop $BUILDER
docker buildx rm $BUILDER
