SHELL=/bin/bash -o pipefail
TAG  = acmenet/`basename ${PWD}`

export DOCKER_BUILDKIT = 1

.PHONY: help
.DEFAULT_GOAL := help
help:  ## Show make help
	@grep --no-filename --color=never -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| awk 'BEGIN { FS = ":.*?## " }; { printf "\033[36m%-30s\033[0m %s\n", $$1, $$2 }' \
	| sort

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
	docker buildx create --platform linux/amd64 --use --name amd64
	docker buildx create --platform linux/arm64 --use --name arm64
endif

.PHONY: build-image
build-image:  ## Build main LTSP image for network booting
	@docker buildx build \
		--file ./build/Dockerfile ./build \
		--output ./images \
		--platform linux/amd64

.PHONY: build-image-remote
build-image-remote:  ## Build on remote node main LTSP image for network booting
	@export DOCKER_HOST="ssh://$(shell \
		docker logs ltspfarm-http --since 1h 2>&1 \
		| grep "ltspfarm/x86_64" \
		| grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' \
		| uniq | shuf -n 1 \
	)" && make build-image

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
