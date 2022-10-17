# ltspfarm
Automated LTSP deployment and the PXE-bootable servers farm for Docker Containers


# Update base LTSP Docker Image and restart Docker Containers
$ docker-compose down
$ make cleanup-all
$ make build-image
$ docker-compose up --detach


# Intel NUC Preparing

...
