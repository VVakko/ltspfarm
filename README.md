# ltspfarm

Automated **LTSP** deployment and the **PXE**-bootable servers farm for Docker Containers


## Initial Preparing LTSP Farm

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
```


## Building LTSP Base and Docker Images

If **Raspberry Pi** will be used as a server, then docker must be additionally prepared to build x86_64 images:
```sh
$ make buildx-install
```

Next, you need to build a disk image for PXE-booting and build docker **LTSP** containers:
```sh
$ make build-image
$ make build-ltsp
```

After building the images, you can run our docker containers:
```sh
$ docker compose up --detach
```
> After any changes in the `./ltsp` folder, the `ltspfarm-conf` container will automatically rebuild `ltsp.img`.

The image building on the **Intel NUC** computer will last about 3.5 minutes. But if this image is builded on a computer **Raspberry Pi 4**, then it will take about 80 minutes. Therefore, in the second case, it makes sense to transfer the building process to one of our nodes. It is very simple to do this. It is necessary that at least one note is started. Next, instead of the `make build-image` command, you need to run the command:
```sh
$ make build-image-remote
```


## Preparing Server Host (Raspberry Pi / Intel NUC)

...
