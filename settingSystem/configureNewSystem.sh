#!/bin/bash

# Connect to the server using the ssh-key
# You are need to create ssh-key using ssh-keygen or puttygen
# sudo ~/.ssh 
# sudo chown user:user ~/.ssh
# chmod 0700 ~/.ssh
# touch ~/.ssh/authorized_keys
# chmod 0600 ~/.ssh/authorized_keys
# Copy id_rsa_key.pub on linux server
# cat id_rsa_key.pub >> ~/.ssh/authorized_keys

sudo dnf update

rpm -Uhv http://rpms.remirepo.net/enterprise/remi-release-8.rpm
rpm -Uhv https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

sudo dnf -y install vim mc tar binutils java elfutils elfutils-libelf 
sudo dnf -y install gcc gcc-c++ glibc glibc-common glibc-devel cpp 
sudo dnf -y install make sysstat libaio libaio-devel unixODBC unixODBC-devel 
sudo dnf -y install net-tools bind-utils epel-release iscsi-initiator-utils 
sudo dnf -y install elfutils-libelf-devel network-scripts
sudo dnf -y install compat-lib* ksh iftop htop atop lsof 
sudo dnf -y install wget bzip2 traceroute gdisk unzip zip

sudo dnf config-manager --set-enabled powertools
sudo dnf -y xeyes
sudo dnf -y install xorg-x11-server-Xorg xorg-x11-xauth xorg-x11-apps

# Configure sshd
## Change new port
sudo sed -i.bak 's/#Port 22/Port 55555/' /etc/ssh/sshd_config
## Disable connect root
sudo sed 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
## Enalbe StrictMode
sudo sed 's/#StrictModes yes/StrictModes yes/' /etc/ssh/sshd_config
## Disable passowrd authentication
## Check connection with ssh-key
sudo sed 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo firewall-cmd --permanent --service=ssh --add-port=2233/tcp
sudo systemctl restart firewalld
sudo systemctl restart sshd