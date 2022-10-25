SHELL=/bin/bash -o pipefail
TAG  = acmenet/`basename ${PWD}`

export DOCKER_BUILDKIT = 1

buildx-install:
ifeq ($(shell uname --hardware-platform), x86_64)
	echo "Install buildx for amd64 (x86_64)..."
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	docker buildx create --name multiarch --driver docker-container --use
	docker buildx inspect --bootstrap
else ifeq ($(shell uname --hardware-platform), aarch64)
	echo "Install buildx for arm64 (aarch64)..."
	docker run --rm --privileged tonistiigi/binfmt --install amd64,arm64
	docker buildx create --platform linux/amd64 --use --name amd64
	docker buildx create --platform linux/arm64 --use --name arm64
endif

build-image:
	@docker buildx build \
		--file ./build/Dockerfile ./build \
		--output ./images \
		--platform linux/amd64

REMOTE_HOST := $(shell \
	docker logs ltspfarm-http --since 1h 2>&1 \
	| grep "ltspfarm/x86_64" \
	| grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' \
	| uniq | shuf -n 1 \
)
build-image-remote:
	@export DOCKER_HOST=ssh://$(REMOTE_HOST) && make build-image

build-ltsp:
	@docker buildx build \
		--tag ${TAG} \
		--file ./build/Dockerfile.ltsp ./build \
		--load

cleanup-all: cleanup-images cleanup-volumes

cleanup-images:
	docker rmi `docker images --filter "dangling=true" -q 2>/dev/null` 2>/dev/null || true

cleanup-volumes:
	docker rm -v `docker ps --filter "status=exited" -q 2>/dev/null` 2>/dev/null || true
