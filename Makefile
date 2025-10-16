SHELL=/bin/bash -o pipefail
TAG  = acmenet/`basename ${PWD}`

export DOCKER_BUILDKIT = 1

# The general logic of getting an remote IP and setting DOCKER_HOST variable
define REMOTE_EXEC
IP=$$(docker logs ltspfarm-http --since 1h 2>&1 \
	| grep "ltspfarm/x86_64" \
	| grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' \
	| uniq | shuf -n 1); \
export DOCKER_HOST="ssh://$$IP";
endef

.PHONY: help
.DEFAULT_GOAL := help
help:  ## Show make help
	@grep --no-filename --color=never -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| awk 'BEGIN { FS = ":.*?## " }; { printf "\033[36m%-30s\033[0m %s\n", $$1, $$2 }' \
	| sort

.PHONY: build-image-for-platform
build-image-for-platform:
	@docker buildx build \
		--file ./build/Dockerfile ./build \
		--output ./images \
		--platform $(PLATFORM) \
		$(EXTRA_BUILD_ARGS); \
	touch -m ./ltsp

.PHONY: build-image
build-image: PLATFORM = linux/amd64
build-image: build-image-for-platform  ## Build main LTSP image for network booting (amd64)

.PHONY: build-image-arm64
build-image-arm64: PLATFORM = linux/arm64
build-image-arm64: build-image-for-platform  ## Build main LTSP image for network booting (arm64)

.PHONY: build-image-arm64-no-fw
build-image-arm64-no-fw: PLATFORM = linux/arm64
build-image-arm64-no-fw: EXTRA_BUILD_ARGS = --build-arg EXCLUDE_FIRMWARE=1
build-image-arm64-no-fw: build-image-for-platform  ## Build main LTSP image for network booting (arm64, without firmware)

.PHONY: build-image-remote
build-image-remote:  ## Build on remote x86_64 node main LTSP image (amd64)
	@$(REMOTE_EXEC) make build-image

.PHONY: build-image-remote-arm64
build-image-remote-arm64:  ## Build on remote x86_64 node (arm64, with buildx setup)
	@$(REMOTE_EXEC) make buildx-install build-image-arm64

.PHONY: build-image-remote-arm64-no-fw
build-image-remote-arm64-no-fw:  ## Build on remote x86_64 node (arm64, without firmware)
	@$(REMOTE_EXEC) make buildx-install build-image-arm64-no-fw

.PHONY: buildx-install
buildx-install:  ## Install dependencies for multi-platform building
ifeq ($(shell uname --hardware-platform), x86_64)
	@echo "Install buildx for amd64 (x86_64)..."
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	docker buildx create --driver docker-container --use --name multiarch
	docker buildx inspect --bootstrap
else ifeq ($(shell uname --hardware-platform), aarch64)
	@echo "Install buildx for arm64 (aarch64)..."
	docker run --rm --privileged tonistiigi/binfmt --install amd64,arm64
#	docker buildx create --platform linux/amd64 --use --name amd64
#	docker buildx create --platform linux/arm64 --use --name arm64
endif

.PHONY: build-ltsp
build-ltsp:  ## Build LTSP docker images for running LTSP farm
	@docker buildx build \
		--tag ${TAG} \
		--file ./build/Dockerfile.ltsp ./build \
		--load

.PHONY: cleanup-all
cleanup-all: cleanup-containers cleanup-images cleanup-volumes  ## Remove unused docker containers, images and volumes

.PHONY: cleanup-containers
cleanup-containers:  ## Remove unused docker containers
	docker rm -v `docker ps --filter "status=exited" -q 2>/dev/null` 2>/dev/null || true

.PHONY: cleanup-images
cleanup-images:  ## Remove dangling docker images
	docker rmi `docker images --filter "dangling=true" -q 2>/dev/null` 2>/dev/null || true

.PHONY: cleanup-volumes
cleanup-volumes:  ## Remove dangling docker volumes
	docker volume rm `docker volume ls --filter "dangling=true" -q 2>/dev/null` 2>/dev/null || true
