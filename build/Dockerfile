#-------------------------------------------------------------------------------
# Base Part Used for LTSP-Server and LTSP-Client
#-------------------------------------------------------------------------------

FROM ubuntu:22.04 as ltsp

ENV DEBIAN_FRONTEND="noninteractive"
ENV VERSION="2022-10-25"

# Install updates and LTSP package
RUN apt-get -y update \
 && apt-get -y upgrade \
 && apt-get -y install \
	wget \
 && apt-get clean

RUN wget -P /etc/apt/trusted.gpg.d/  https://ltsp.org/misc/ltsp_ubuntu_ppa.gpg \
 && wget -P /etc/apt/sources.list.d/ https://ltsp.org/misc/ltsp-ubuntu-ppa-focal.list \
 && wget -P /etc/apt/sources.list.d/ https://ltsp.org/misc/ltsp-ubuntu-proposed-focal.list

RUN apt-get -y update \
 && apt-get -y install \
	ltsp-binaries \
	ltsp-cloud \
 && apt-get clean


#-------------------------------------------------------------------------------
# Installing Kernel and Basic Software
#-------------------------------------------------------------------------------

FROM ltsp as rootfs-pre

# Install packages, cleanup and disable auto-upgrades
RUN echo 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";\n' \
	>>/etc/apt/apt.conf.d/01norecommend \
 && apt-get update \
 && apt-get -y install \
	bash-completion \
	bc \
	cron \
	curl \
	gnupg \
	htop \
	initramfs-tools \
	jnettop \
	jq \
	linux-image-generic \
	lm-sensors \
	mc \
	nano \
	net-tools \
	nfs-common \
	openssh-server \
	rsync \
	screen \
	squashfs-tools \
	tcpdump \
	telnet \
	ubuntu-minimal \
	wget \
 && apt-get purge -y --auto-remove \
	ubuntu-advantage-tools \
	vim-common \
	vim-tiny \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && rm -f /etc/apt/apt.conf.d/20auto-upgrades

# Disable apparmor profiles
RUN mkdir -p /etc/apparmor.d/disable/ \
 && find /etc/apparmor.d \
	-maxdepth 1 \
	-type f \
	-name "sbin.*" \
	-o -name "usr.*" \
	-exec ln -sf "{}" /etc/apparmor.d/disable/ \;

# Setup locales
RUN printf "%s\n" \
	"LANG=en_US.UTF-8" \
	"LC_TIME=POSIX" \
	"LC_CTYPE=en_US.UTF-8" \
	>/etc/locale.conf \
 && locale-gen en_US.UTF-8 ru_RU.UTF-8

# Disable systemd-resolved
RUN systemctl disable systemd-resolved.service \
 && systemctl mask systemd-resolved.service

# Install Docker
RUN mkdir -p /etc/apt/keyrings \
 && curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
	| gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
 && chmod a+r /etc/apt/keyrings/docker.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
 	https://download.docker.com/linux/ubuntu \
  	$(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null \
 && apt-get -y update \
 && apt-get -y install \
	containerd.io \
 	docker-ce \
	docker-ce-cli \
	docker-compose-plugin \
 && apt-mark hold docker-ce


#-------------------------------------------------------------------------------
# Build rootfs Image
#-------------------------------------------------------------------------------

FROM rootfs-pre as rootfs

# Generate motd
COPY motd /etc/motd
RUN sed -i "s/\${VERSION}/${VERSION}/" /etc/motd

# Generate image
ENV OMIT_FUNCTIONS="remove_users"
RUN ltsp image -I /


#-------------------------------------------------------------------------------
# Copying created rootfs images to local filesystem
#-------------------------------------------------------------------------------

FROM scratch AS export-rootfs

COPY --from=rootfs /srv/ltsp/images ./ltsp
COPY --from=rootfs /srv/tftp/ltsp ./tftp
