#!/usr/bin/env bash

set -e

for i in "$@"
do
case $i in
    -nv=*|--nuclio-version=*)
    NUCLIO_LABEL="${i#*=}"
    shift # past argument=value
    ;;

    -prin=*|--prebaked-registry-image-name=*)
    PREBAKED_REGISTRY_IMAGE_NAME="${i#*=}"
    shift # past argument=value
    ;;

    -bri=*|--base-registry-image=*)
    BASE_REGISTRY_IMAGE="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done

if [[ -z ${NUCLIO_LABEL} ]]; then
    printf "NUCLIO_LABEL not provided, cannot perform build\n"
    exit 1
fi

if [[ -z ${PREBAKED_REGISTRY_IMAGE_NAME} ]]; then
    printf "PREBAKED_REGISTRY_IMAGE_NAME not provided, cannot perform build\n"
    exit 1
fi

if [[ -z ${BASE_REGISTRY_IMAGE} ]]; then
    printf "BASE_REGISTRY_IMAGE not provided, cannot perform build\n"
    exit 1
fi

printf "NUCLIO_LABEL                  = ${NUCLIO_LABEL}\n"
printf "PREBAKED_REGISTRY_IMAGE_NAME  = ${PREBAKED_REGISTRY_IMAGE_NAME}\n"
printf "BASE_REGISTRY_IMAGE           = ${BASE_REGISTRY_IMAGE}\n"
printf "\n"

printf "\n## Pulling muted-registry ${BASE_REGISTRY_IMAGE}\n"
docker pull ${BASE_REGISTRY_IMAGE}

printf "\n## Releasing prebaked-registry-nuclio version ${NUCLIO_LABEL}, with images from nuclio ${NUCLIO_LABEL}\n"

docker rm -f prebaked-registry-nuclio || true

printf "\n## Running local registry: ${BASE_REGISTRY_IMAGE} \n"
docker run --user 1000:1000 --rm -d -p 5000:5000 --name=prebaked-registry-nuclio ${BASE_REGISTRY_IMAGE}

IMAGES_TO_BAKE=(
"quay.io/nuclio/handler-builder-python-onbuild:${NUCLIO_LABEL}-amd64"
"quay.io/nuclio/handler-builder-golang-onbuild:${NUCLIO_LABEL}-amd64"
"quay.io/nuclio/handler-builder-nodejs-onbuild:${NUCLIO_LABEL}-amd64"
"quay.io/nuclio/handler-builder-java-onbuild:${NUCLIO_LABEL}-amd64"
"quay.io/nuclio/handler-builder-dotnetcore-onbuild:${NUCLIO_LABEL}-amd64"
"quay.io/nuclio/handler-builder-ruby-onbuild:${NUCLIO_LABEL}-amd64"
)

printf "\nResolved images to bake:\n"
printf '%s\n' "${IMAGES_TO_BAKE[@]}"

for ORIG_IMAGE in "${IMAGES_TO_BAKE[@]}"
do
  printf "\n### Pulling docker image\n"
  docker pull $ORIG_IMAGE

  declare RETAGGED_IMAGE
  RETAGGED_IMAGE=${ORIG_IMAGE/"quay.io"/"localhost:5000"}

  printf "\n### Tagging image to local prebaked registry\n"
  docker tag $ORIG_IMAGE $RETAGGED_IMAGE

  printf "\n### Pushing image to prebaked registry\n"
  docker push $RETAGGED_IMAGE
done

printf "\n## View catalog - Listing baked images in registry\n"
http get localhost:5000/v2/_catalog

printf "\n## Commiting prebaked local registry image\n"
declare PREBAKED_REGISTRY_IMAGE
PREBAKED_REGISTRY_IMAGE="${PREBAKED_REGISTRY_IMAGE_NAME}:${NUCLIO_LABEL}"

docker commit --message "Baking nuclio images for ${NUCLIO_LABEL}" prebaked-registry-nuclio ${PREBAKED_REGISTRY_IMAGE}
docker rm -f prebaked-registry-nuclio
printf "\n## Completed building prebaked-registry for nuclio - image: ${PREBAKED_REGISTRY_IMAGE}\n"

# For visual verification
printf "\n## Running prebaked local registry to validate content\n"
docker run --user 1000:1000 --rm -d -p 5000:5000 --name=prebaked-registry-nuclio ${PREBAKED_REGISTRY_IMAGE}
http get localhost:5000/v2/_catalog
docker rm -f prebaked-registry-nuclio
