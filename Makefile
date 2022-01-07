TAG  = acmenet/`basename ${PWD}`
NAME = dev-`basename ${PWD}`
UID  = `id -u`
GID  = `id -g`
MNT  = /mnt/local

build-image:
	DOCKER_BUILDKIT=1 && docker build --tag ${TAG} --file ./build/Dockerfile ./build

build-image-and-run: build-image
	docker run --rm --name ${NAME} -it ${TAG}

cleanup-all: cleanup-images cleanup-volumes

cleanup-images:
	docker rmi `docker images --filter "dangling=true" -q 2>/dev/null` -q 2>/dev/null || true

cleanup-volumes:
	docker rm -v `docker ps --filter "status=exited" -q 2>/dev/null` -q 2>/dev/null || true

copy-srv-to-local:
	docker run --volume ${PWD}:${MNT} --rm --entrypoint cp ${TAG} -r /srv ${MNT}
	docker run --volume ${PWD}:${MNT} --rm -it ${TAG} /usr/bin/chown -R ${UID}:${GID} ${MNT}
