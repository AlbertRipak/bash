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
sudo dnf -y install yum install xorg-x11-utils*
sudo dnf -y install libnsl
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

echo "STEP 7: Create user and group (oracle and grid)!"
sudo groupadd -g 54321 oinstall
sudo groupadd -g 54322 dba
sudo groupadd -g 54323 oper
sudo groupadd -g 54324 backupdba
sudo groupadd -g 54325 dgdba
sudo groupadd -g 54326 kmdba
sudo groupadd -g 54330 racdba

sudo useradd -u 54321 -g oinstall -G oinstall,dba,oper,backupdba,dgdba,kmdba,racdba,asmdba oracle
sudo passwd oracle

echo "STEP 8: Create direcotry for oracle and oracle grid!"
sudo mkdir -p /u01/app/oracle
sudo mkdir -p /u01/app/oracle/product/11.2.0/dbhome_1
sudo chown -R oracle:oinstall /u01

echo "STEP 9: Setting grid profile!"
sudo echo 'TMP=/tmp; export TMP
TMPDIR=$TMP; export TMPDIR
ORACLE_HOSTNAME=$HOSTNAME; export ORACLE_HOSTNAME
ORACLE_BASE=/u01/app/grid; export ORACLE_BASE
ORACLE_HOME=$ORACLE_BASE/product/11.2.0/grid_home; export ORACLE_HOME
ORACLE_SID=+ASM; export ORACLE_SID
ORACLE_TERM=xterm; export ORACLE_TERM
BASE_PATH=/usr/sbin:$PATH; export BASE_PATH
PATH=$ORACLE_HOME/bin:$GRID_HOME/bin:$BASE_PATH; export PATH
LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib; export LD_LIBRARY_PATH
CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib; export CLASSPATH
' >> /home/grid/.bash_profile
sudo chown -R grid:oinstall /home/grid/.bash_profile

echo "STEP 10: Upgrade kernel parameters!"
sudo echo "
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmall = 2097152
kernel.shmmax = 536870912
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048586
" >> /etc/sysctl.conf

sysctl -p

echo "STEP 11: Set parameters for user oracle and grid!"
sudo echo "
oracle soft nproc 2047
oracle hard nproc 16384
oracle soft nofile 4096
oracle hard nofile 65536
oracle soft stack  10240
" >> /etc/security/limits.conf

echo "session    required     pam_limits.so
" >> /etc/pam.d/limits.so