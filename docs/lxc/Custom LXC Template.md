# Generate a Custom LXC Image with OpenSSH Installed and Root Access

## Install Dependencies
``` bash
sudo apt update
sudo apt install lxc wget xz-utils nano
```
## Download OpenSSH Server and Dependencies

``` bash
wget http://ports.ubuntu.com/pool/main/o/openssh/openssh-server_8.2p1-4ubuntu0.9_arm64.deb
wget http://ports.ubuntu.com/pool/main/t/tcp-wrappers/libwrap0_7.6.q-31build2_arm64.deb
wget http://ports.ubuntu.com/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_arm64.deb
wget http://ports.ubuntu.com/pool/main/o/openssh/openssh-sftp-server_8.2p1-4ubuntu0.9_arm64.deb
wget http://ports.ubuntu.com/pool/main/o/openssh/openssh-client_8.2p1-4ubuntu0.9_arm64.deb
```

## Create and Configure LXC Container
### Check and Create Internet Interface
``` bash
brctl show
brctl addbr lxcbr0
```

### Create and Start LXC Container
``` bash
lxc-create -n ubuntu-22-custom -t download
lxc-start -n ubuntu-22-custom
lxc-stop -n ubuntu-22-custom
```

### Copy Debian Packages to Container
``` bash
cp *.deb /var/lib/lxc/ubuntu-22-custom/rootfs/root/
```


### Start and Attach Container
``` bash
lxc-start -n ubuntu-22-custom
lxc-attach -n ubuntu-22-custom
```


### Install Packages in Container
``` bash
dpkg -i libssl1.1_1.1.1f-1ubuntu2_arm64.deb
dpkg -i libwrap0_7.6.q-31build2_arm64.deb
dpkg -i openssh-client_8.2p1-4ubuntu0.9_arm64.deb
dpkg -i openssh-sftp-server_8.2p1-4ubuntu0.9_arm64.deb
dpkg -i openssh-server_8.2p1-4ubuntu0.9_arm64.deb
```


### Configure SSH in Container
``` bash
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
```
### Exit and Stop Container
``` bash
exit
lxc-stop -n ubuntu-22-custom
```


## Export the Container
``` bash
tar --numeric-owner -czvf ubuntu-22-custom.tar.gz -C /var/lib/lxc/ubuntu-22-custom/rootfs .
```