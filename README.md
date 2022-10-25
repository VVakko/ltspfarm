# ltspfarm

Automated LTSP deployment and the PXE-bootable servers farm for Docker Containers


# Initial Building LTSP Farm

```sh
# Clone ltspfarm repository
$ sudo su
$ cd /srv/
$ git clone https://github.com/VVakko/ltspfarm.git
$ cd ltspfarm/
# Create folders for root and main user (use your user name instead of username in commands)
$ mkdir -p ltsp/data/users/username/
$ ln -s username ltsp/data/users/root
# Set password for user root
$ openssl passwd -6 >ltsp/data/users/root.password.txt
Password: 
Verifying - Password: 
# Set password for user username
$ openssl passwd -6 >ltsp/data/users/username.password.txt
Password: 
Verifying - Password: 
# Set groups for user username
$ echo "adm,audio,cdrom,docker,plugdev,sudo,systemd-journal,video" \
    >ltsp/data/users/username.groups.txt
# Generate SSH key if you don't have one yet
$ ssh-keygen -t rsa
# Set SSH key for passwordless login on cluster nodes
$ mkdir -p ltsp/data/users/username/.ssh/
$ cat ~/.ssh/id_rsa.pub >>ltsp/data/users/username/.ssh/authorized_keys
$ chmod 0600 ltsp/data/users/username/.ssh/authorized_keys
...
# Build LTSP Docker Image and start containers
$ make buildx-install  # If you will build amd64 images on Raspberry Pi
$ make build-image
$ docker-compose up --detach
```

# Update Base LTSP Docker Images

```sh
$ docker-compose down
$ make cleanup-all
$ make build-image
$ docker-compose up --detach
```


# Preparing Server Host (Raspberry Pi / Intel NUC)

...
