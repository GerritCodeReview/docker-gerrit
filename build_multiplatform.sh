#!/bin/bash

# By default it builds images and loads them into local docker (--load is assumed)
# however one can specify --push and it will be pushed to the dockerhub.
# Note that in the later case one needs to be loged in to 'gerritcodereview' account.

DESTINATION=$1

if [ -z ${var+x} ]; then
  DESTINATION="--load"
fi

echo "### Building images for $DESTINATION destination"

BUILDER=gerrit-multiplatform-image-builder
PLATFORMS="linux/amd64,linux/arm64"
DOCKER_USER=gerritcodereview/gerrit

function create_builder() {
  if [[ "$OSTYPE" == "linux"* ]]; then
    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
  fi
  docker buildx create --name $BUILDER --platform "$PLATFORMS" --driver docker-container --use
  docker buildx inspect --bootstrap
}

STATUS="$(docker buildx inspect $BUILDER >/dev/null 2>&1 | grep Status:)"

if [ $? != 0 ]; then
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
