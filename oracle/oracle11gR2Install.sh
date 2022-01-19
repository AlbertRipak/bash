#!/bin/bash

echo "STEP 1: Update system!"
yum -y update

echo "STEP 2: Install mc package!"
yum -y install mc 
cp /usr/share/mc/syntax/sh.syntax /usr/share/mc/syntax/unknown.syntax

echo "STEP 3: Disable firewalld!"
sed -i.bak 's/=enforcing/=disabled/' /etc/sysconfig/selinux 
setenforce 0
systemctl stop firewalld
systemctl disable firewalld

echo "STEP 4: Install iptables and packages need oracle database sowtfare!"
yum -y install iptables
yum -y install binutils java elfutils elfutils-libelf gcc gcc-c++ glibc glibc-common glibc-devel cpp make sysstat libaio libaio-devel unixODBC unixODBC-devel
yum install -y xorg-x11-server-Xorg xorg-x11-xauth xorg-x11*

rpm -Uhv http://rpms.remirepo.net/enterprise/remi-release-8.rpm
rpm -Uhv https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum -y install chrony 
yum -y install iftop htop atop lsof wget bzip2 traceroute gdisk unzip zip

# systemctl start iptables
# systemctl enable iptables

echo "STEP 4.1: Config date!"
systemctl start chronyd
systemctl enable chronyd
date
cal
timedatectl set-timezone Europe/Kiev

echo "STEP 5: Create and configure file iptables.sh!"
echo '
#!/bin/bash
#
# Объявление переменных
export IPT="iptables"

# Интерфейс который смотрит в интернет
export WAN=eth0
export WAN_IP=YOUR_IP_ADDRESS

# Очистка всех цепочек iptables
$IPT -F
$IPT -F -t nat
$IPT -F -t mangle
$IPT -X
$IPT -t nat -X
$IPT -t mangle -X

# Установим политики по умолчанию для трафика, не соответствующего ни одному из правил
$IPT -P INPUT DROP
$IPT -P OUTPUT DROP
$IPT -P FORWARD DROP

# разрешаем локальный траффик для loopback
$IPT -A INPUT -i lo -j ACCEPT
$IPT -A OUTPUT -o lo -j ACCEPT

# Разрешаем исходящие соединения самого сервера
$IPT -A OUTPUT -o $WAN -j ACCEPT

# Состояние ESTABLISHED говорит о том, что это не первый пакет в соединении.
# Пропускать все уже инициированные соединения, а также дочерние от них
$IPT -A INPUT -p all -m state --state ESTABLISHED,RELATED -j ACCEPT
# Пропускать новые, а так же уже инициированные и их дочерние соединения
$IPT -A OUTPUT -p all -m state --state ESTABLISHED,RELATED -j ACCEPT
# Разрешить форвардинг для уже инициированных и их дочерних соединений
$IPT -A FORWARD -p all -m state --state ESTABLISHED,RELATED -j ACCEPT

# Включаем фрагментацию пакетов. Необходимо из за разных значений MTU
$IPT -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

# Отбрасывать все пакеты, которые не могут быть идентифицированы
# и поэтому не могут иметь определенного статуса.
$IPT -A INPUT -m state --state INVALID -j DROP
$IPT -A FORWARD -m state --state INVALID -j DROP

# Приводит к связыванию системных ресурсов, так что реальный
# обмен данными становится не возможным, обрубаем
$IPT -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
$IPT -A OUTPUT -p tcp ! --syn -m state --state NEW -j DROP

# Рзрешаем пинги
$IPT -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# Открываем порт для ssh
$IPT -A INPUT -i $WAN -p tcp --dport 22 -j ACCEPT
# Открываем порт для http
$IPT -A INPUT -i $WAN -p tcp --dport 80 -j ACCEPT
# Открываем порт для https
$IPT -A INPUT -i $WAN -p tcp --dport 443 -j ACCEPT

# Логирование
# Все что не разрешено, но ломится отправим в цепочку undef

$IPT -N undef_in
$IPT -N undef_out
$IPT -N undef_fw
$IPT -A INPUT -j undef_in
$IPT -A OUTPUT -j undef_out
$IPT -A FORWARD -j undef_fw

# Логируем все из undef

$IPT -A undef_in -j LOG --log-level info --log-prefix "-- IN -- DROP "
$IPT -A undef_in -j DROP
$IPT -A undef_out -j LOG --log-level info --log-prefix "-- OUT -- DROP "
$IPT -A undef_out -j DROP
$IPT -A undef_fw -j LOG --log-level info --log-prefix "-- FW -- DROP "
$IPT -A undef_fw -j DROP

# Записываем правила
/sbin/iptables-save  > /etc/sysconfig/iptables
' >> /etc/iptables.sh
chmod 0740 /etc/iptables.sh

echo "STEP 5: Substutute port for ssh on 55555!"
sed -i.bak 's/#Port 22/Port 55555/' /etc/ssh/sshd_config

echo "STEP 6: Install pakcages for system!"
yum -y install net-tools bind-utils epel-release \
	iscsi-initiator-utils \
	elfutils-libelf-devel \
  network-scripts \
  kmod-oracleasm \
  compat-lib* \
  ksh

echo "STEP 7: Create user and group (oracle and grid)!"
groupadd -g 54321 oinstall
groupadd -g 54322 dba
groupadd -g 54323 oper
groupadd -g 54324 backupdba
groupadd -g 54325 dgdba
groupadd -g 54326 kmdba
groupadd -g 54327 asmdba
groupadd -g 54328 asmoper
groupadd -g 54329 asmadmin
groupadd -g 54330 racdba

useradd -u 54321 -g oinstall -G oinstall,dba,oper,backupdba,dgdba,kmdba,racdba,asmdba oracle
passwd oracle

useradd -u 54331 -g oinstall -G oinstall,dba,asmdba,asmoper,asmadmin,racdba grid
passwd grid

echo "STEP 8: Create direcotry for oracle and oracle grid!"
mkdir -p /u01/app/oracle
mkdir -p /u01/app/oracle/product/11.2.0/dbhome_1
chown -R oracle:oinstall /u01

mkdir -p /u01/app/grid
mkdir -p /u01/app/grid/product/11.2.0/grid_home
chown -R grid:oinstall /u01/app/grid
chmod -R 775 /u01

echo "STEP 9: Setting grid profile!"
echo 'TMP=/tmp; export TMP
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
chown -R grid:oinstall /home/grid/.bash_profile

echo "STEP 10: Upgrade kernel parameters!"
echo "
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmall = 2097152
kernel.shmmax = 4294967295
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
" >> /etc/sysctl.conf

sysctl -p

echo "STEP 11: Set parameters for user oracle and grid!"
echo "
oracle soft nproc 2047
oracle hard nproc 16384
oracle soft nofile 1024
oracle hard nofile 65536

grid soft nproc 2047
grid hard nproc 16384
grid soft nofile 1024
grid hard nofile 65536
" >> /etc/security/limits.conf

echo '
if [ $USER = "oracle" ];
then 
if [ $SHELL = "/bin/ksh" ]; then
ulimit -p 16384
ulimit -n 65536
else
ulimit -u 16384 -n 65536
fi 
fi

if [ $USER = "grid" ];
then 
if [ $SHELL = "/bin/ksh" ]; then
ulimit -p 16384
ulimit -n 65536
else
ulimit -u 16384 -n 65536
fi 
fi
' >> /etc/profile

echo '
if ( $USER = "oracle" ) then 
limit maxproc 16384
limit descriptors 65536
endif

if ( $USER = "grid" ) then 
limit maxproc 16384
limit descriptors 65536
endif
' >> /etc/csh.login

echo "STEP 12: Add new session in /etc/pam.d/login"
echo "session required pam_limits.so" >> /etc/pam.d/login

echo "STEP 13: Settings bash_profile for user oracle!"
echo 'TMP=/tmp; export TMP
TMPDIR=$TMP; export TMPDIR
ORACLE_HOSTNAME=$HOSTNAME; export ORACLE_HOSTNAME
ORACLE_BASE=/u01/app/oracle; export ORACLE_BASE
ORACLE_HOME=$ORACLE_BASE/product/11.2.0/dbhome_1; export ORACLE_HOME
ORACLE_SID=orcl; export ORACLE_SID
ORACLE_TERM=xterm; export ORACLE_TERM
BASE_PATH=/usr/sbin:$PATH; export BASE_PATH
PATH=$ORACLE_HOME/bin:/usr/bin:/usr/ccs/bin:/etc:/usr/binx11:/usr/loca/bin:$GRID_HOME/bin:$BASE_PATH; export PATH
LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib; export LD_LIBRARY_PATH
CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib; export CLASSPATH
' >> /home/oracle/.bash_profile
chown -R oracle:oinstall /home/oracle/.bash_profile

echo "STEP 14: Start .bash_profile from /home/grid!"
cd /home/grid
. ./.bash_profile

echo "STEP 14.1: Setting history comand!"

echo "export HISTSIZE=10000
export HISTTIMEFORMAT=\"%h %d %H:%M:%S \"
PROMPT_COMMAND='history -a'
export HISTIGNORE=\"ls:ll:history:w:\"" >> /root/.bashrc

echo "STEP 15: You can install oracle of oracle grid infrastructure!"
echo "You need install and configure oracleasm!"
echo "This is ulr where you can download oracleasm pakcages ---> https://www.oracle.com/linux/downloads/linux-asmlib-rhel7-downloads.html"

# THE END!


https://logic.edchen.org/how-to-resolve-error-in-invoking-target-agent_nmhs-of-makefile-ins_emagent-mk/
# string 176
vim /u01/app/oracle/product/11.2.0/dbhome_1/sysman/lib/ins_emagent.mk
#   comment old string and add new
    #$(MK_EMAGENT_NMECTL)
    $(MK_EMAGENT_NMECTL) -lnnz11
# push Retry