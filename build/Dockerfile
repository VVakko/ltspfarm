#-------------------------------------------------------------------------------
# Base Part Used for LTSP-Server and LTSP-Client
#-------------------------------------------------------------------------------

FROM ubuntu:24.04 AS ltsp

# Install updates and LTSP package
ENV DEBIAN_FRONTEND="noninteractive"
RUN apt-get -y update \
 && apt-get -y upgrade \
 && apt-get -y install \
	patch software-properties-common \
 && apt-get clean

RUN add-apt-repository -y ppa:ltsp/proposed \
 && apt-get -y update \
 && apt-get -y install \
	ltsp-binaries \
	ltsp \
 && apt-get clean

# Applying LTSP patches for HTTP and Docker compatibility
# https://github.com/ltsp/ltsp/pull/89/
# https://github.com/ltsp/ltsp/pull/90/
COPY ltsp-patches /tmp/ltsp-patches
RUN find /tmp/ltsp-patches -name "*.patch" -type f -exec patch -p1 -d /usr/share/ltsp -i {} \; \
 && rm -rf /tmp/ltsp-patches


#-------------------------------------------------------------------------------
# Installing Kernel and Basic Software
#-------------------------------------------------------------------------------

FROM ltsp AS rootfs-pre
ENV VERSION="2025-10-15"

# Install packages, cleanup and disable auto-upgrades
RUN echo 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";\n' \
	>>/etc/apt/apt.conf.d/01norecommend \
 && apt-get update \
 && apt-get -y install \
    apparmor \
	bash-completion \
	bc \
	cron \
	curl \
	gnupg \
	htop \
	initramfs-tools \
	jnettop \
	jq \
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
	wget
RUN if [ "$(uname -m)" = "x86_64" ]; then \
		apt-get -y install linux-image-generic; \
	elif [ "$(uname -m)" = "aarch64" ]; then \
		apt-get -y install linux-image-raspi linux-firmware-raspi ubuntu-raspi-settings; \
	fi
RUN apt-get purge -y --auto-remove \
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

FROM rootfs-pre AS rootfs

# Generate motd
COPY motd /etc/motd
RUN sed -i "s/\${VERSION}/${VERSION}/" /etc/motd

# Generate image
ENV OMIT_FUNCTIONS="remove_users"
RUN if [ "$(uname -m)" = "x86_64" ]; then \
		ltsp image --in-place /; \
	elif [ "$(uname -m)" = "aarch64" ]; then \
		ltsp image --in-place --mksquashfs-params='-comp lzo' /; \
	fi


#-------------------------------------------------------------------------------
# Copying created rootfs images to local filesystem
#-------------------------------------------------------------------------------

FROM scratch AS export-rootfs

COPY --from=rootfs /srv/ltsp/images ./ltsp
COPY --from=rootfs /srv/tftp/ltsp ./tftp
