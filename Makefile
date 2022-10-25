SHELL=/bin/bash -o pipefail
TAG  = acmenet/`basename ${PWD}`
NAME = dev-`basename ${PWD}`
UID  = `id -u`
GID  = `id -g`
MNT  = /mnt/local

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
	docker buildx build \
		--tag ${TAG}-images \
		--file ./build/Dockerfile ./build --output ${PWD}/images \
		--platform linux/amd64
	docker buildx build \
		--tag ${TAG} \
		--file ./build/Dockerfile.ltsp ./build \
		--load

build-image-and-run: build-image
	docker run --rm --name ${NAME} -it ${TAG}

cleanup-all: cleanup-images cleanup-volumes

cleanup-images:
	docker rmi `docker images --filter "dangling=true" -q 2>/dev/null` 2>/dev/null || true

cleanup-volumes:
	docker rm -v `docker ps --filter "status=exited" -q 2>/dev/null` 2>/dev/null || true

copy-srv-to-local:
	docker run --volume ${PWD}:${MNT} --rm --entrypoint cp ${TAG} -r /srv ${MNT}
	docker run --volume ${PWD}:${MNT} --rm -it ${TAG} /usr/bin/chown -R ${UID}:${GID} ${MNT}
