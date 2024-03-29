RELEASE_REGISTRY_URL ?= quay.io
RELEASE_REGISTRY_USER ?= nuclio
IGZ_NUCLIO_REGISTRY_VERSION ?= latest
NUCLIO_LABEL ?= REPLACEME # a released nuclio version label, e.g. 1.3.12 -> will create prebaked-registry-nuclio:1.3.12
BASE_DOCKER_REGISTRY_VERSION=2.7.1
BASE_DOCKER_REGISTRY_IMAGE=$(RELEASE_REGISTRY_URL)/iguazio/muted-registry:2.7.1
PREBAKED_REGISTRY_IMAGE_NAME=$(RELEASE_REGISTRY_URL)/$(RELEASE_REGISTRY_USER)/prebaked-registry-nuclio

# Usage examples:
# > NUCLIO_LABEL=1.3.17 make build

.PHONY: all
all: build release release-stable
	@echo Done.

.PHONY: build
build:
	./build.sh --prebaked-registry-image-name=$(PREBAKED_REGISTRY_IMAGE_NAME) --nuclio-version=$(NUCLIO_LABEL) --base-registry-image=$(BASE_DOCKER_REGISTRY_IMAGE)
	@echo "Done buildling prebaked-registry-nuclio version=$(NUCLIO_LABEL)"

.PHONY: release
release:
	docker push $(PREBAKED_REGISTRY_IMAGE_NAME):$(NUCLIO_LABEL)
	@echo "Done pushing to release registry"

.PHONY: release-stable
release:
	docker tag $(PREBAKED_REGISTRY_IMAGE_NAME):$(NUCLIO_LABEL) $(PREBAKED_REGISTRY_IMAGE_NAME):stable
	docker push $(PREBAKED_REGISTRY_IMAGE_NAME):stable
	@echo "Done pushing stable to release registry"
