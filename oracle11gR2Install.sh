#!/bin/bash

# This sript use for install oracle 11gR2 on centos 8!
yum -y update

# Setting centos 8
yum -y install mc 
cp /usr/share/mc/syntax/sh.syntax /usr/share/mc/syntax/unknown.syntax

sed -i.bak 's/=enforcing/=disabled/' /etc/sysconfig/selinux && \
	setenforce 0 && \
	systemctl stop firewalld && \
	systemctl disable firewalld

# iptables
yum -y install iptables

systemctl start iptables
systemctl enable iptables

cat > /etc/iptables.sh <<EOF 
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
EOF

chmod 0740 /etc/iptables.sh
. /etc/iptables.sh

sed -i.bak 's/#Port 22/Port 55555' /etc/ssh/sshd_config

yum -y install net-tools bind-utils epel-release \
	compat-libcap* \
	iscsi-initiator-utils* \
	elfutils-libelf-devel* \
  network-scripts

 

yum -y localinstall * #в папку перекидуем скачаные пакеты и инсталим  oracleasm-support и oracleasmlib
#yum -y install oracleasm-support.x86_64 
#yum -y install oracleasmlib-2.0.12-1.el6.x86_64.rpm
#wget https://download.oracle.com/otn_software/asmlib/oracleasmlib-2.0.12-1.el6.x86_64.rpm 
#rm -f oracleasmlib-2.0.12-1.ecl6.x86_64.rpm

# cat /etc/resolv.conf
# search localdomain
# nameserver 192.168.0.1
# options timeout:1
# options attempts:5

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

# oracleasm configure -i
# oracleasm init

# oracleasm createdisk CRS1 /dev/sdb1
# oracleasm createdisk DATA1 /dev/sdb2
# oracleasm createdisk FRA1 /dev/sdb3

# для проверки того, были ли созданы ети диски можно выполнить команды
# /etc/init.d/oracleasm listdisks

# нужно создать директорию для бд оракл
mkdir -p /u01/app/oracle
mkdir -p /u01/app/oracle/product/11.2.0/dbhome_1
chown -R oracle:oinstall /u01

# нужно создать директорию для асм
mkdir -p /u01/app/grid
mkdir -p /u01/app/grid/11.2.0/grid_home
chown -R grid:oinstall /u01/app/grid
chmod -R 775 /u01

# редактируем .bash_profile user grid
# .bash_profile
vi /home/oracle/.grid_profile

TMP=/tmp; export TMP
TMPDIR=$TMP; export TMPDIR
ORACLE_HOSTNAME=$HOSTNAME; export ORACLE_HOSTNAME
ORACLE_BASE=/u01/app/grid; export ORACLE_BASE
ORACLE_HOME=$ORACLE_BASE/product/11.2.0/dbhome_1; export ORACLE_HOME
ORACLE_SID=+ASM; export ORACLE_SID
ORACLE_TERM=xterm; export ORACLE_TERM
BASE_PATH=/usr/sbin:$PATH; export BASE_PATH
PATH=$ORACLE_HOME/bin:$GRID_HOME/bin:$BASE_PATH; export PATH
LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib; export LD_LIBRARY_PATH
CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib; export CLASSPATH


# изменение конфигураций ядра, Centos 8
cat /etc/sysctl.conf

vi /etc/sysctl.conf

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


# для того что бы изменение вступили в силу 

sysctl -p
# или
reboot

# Oracle рекомендует ограничиsвать количество процессов и открытых файлов в linux
# для повышения производительности сис. админ должен повысить определенные ограничения
# оболочки для пользователя oracle

vi /etc/security/limits.conf

oracle soft nproc 2047
oracle hard nproc 16384
oracle soft nofile 1024
oracle hard nofile 65536

grid soft nproc 2047
grid hard nproc 16384
grid soft nofile 1024
grid hard nofile 65536

# также нужно добавить следующую строку в 

vi /etc/pam.d/login

session required pam_limits.so

# сис. админ должен также внести изменения в командные оболочки пользователя
# загружаемые при входе в систему. Эти изменения зависят от используемой по умолчанию 
# командной оболочки
# для оболочки Bourne, BASH, Korn необходимо добавить следующие строки в файл

vi /etc/profile

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

# для оболочки С (csh, tcsh)

vi /etc/csh.login

if ( $USER = "oracle" ) then 
limit maxproc 16384
limit descriptors 65536
endif

if ( $USER = "grid" ) then 
limit maxproc 16384
limit descriptors 65536
endif

# создадим пременные окружени, для этого редактируем 

vi /home/oracle/.bash_profile

TMP=/tmp; export TMP
TMPDIR=$TMP; export TMPDIR
ORACLE_HOSTNAME=oracleasm.localdomain; export ORACLE_HOSTNAME
ORACLE_BASE=/u01/app/oracle; export ORACLE_BASE
ORACLE_HOME=$ORACLE_BASE/product/11.2.0/dbhome_1; export ORACLE_HOME
ORACLE_SID=orcl; export ORACLE_SID
ORACLE_TERM=xterm; export ORACLE_TERM
BASE_PATH=/usr/sbin:$PATH; export BASE_PATH
PATH=$ORACLE_HOME/bin:$GRID_HOME/bin:$BASE_PATH; export PATH
LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib; export LD_LIBRARY_PATH
CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib; export CLASSPATH

# чтобы внесенные изменения вступили в силу

cd /home/oracle
. ./.bash_profile

# для успешной установки Oracle требуются дополнительные пакеты
# чтобы проверить установлены ли пакеты 

yum -y install binutils* elfutils* elfutils-libelf* gcc* gcc-c++* glibc* glibc-common* glibc-devel* compat-libstdc++* cpp* make* compat-db* sysstat* libaio* libaio-devel* unixODBS* unixODBS-devel* 
rpm -Uhv binutils elfutils elfutils-libelf gcc gcc-c++ glibc glibc-common glibc-devel compat-libstdc++ cpp make compat-db sysstat libaio libaio-devel unixODBS unixODBS-devel | sort

# запускаем графическую оболочку под юзером root 

xhost +

# ЭТАП УСТАНОВКИ ORACLE

# распаковуе дистрибутив

unzip linux.x64_11gR2_database_1of2.zip
unzip linux.x64_11gR2_database_1of2.zip

# переходим в распакованый каталог

cd ./database

# запускаем 
./runInstaller

# после этого запустится графическая оболочка инсталлятора

# ПОСТ ИНСТАЛЛЯЦИОННЫЙ ЭТАП

# НЕ ФАКТ ЧТО НУЖНО ТАК ДЕЛАТЬ

# для автоматического запуска и остановки СУБД Oracle и слушателя Listener
# вместе со стартом и завершением ос нам нужно отредактирова файл

vi /etc/oratab

ORCL:/u01/app/oracle/product/11.2.0/dbhome_1:YourDB

# вместо YourDB ваша БД

# под пользователем root создадим новый файл автозапуска oracle
# (сценарий инициализации для запуска и завершения работы бд)

#!/bin/bash
#
# oracle Init file for starting and stopping
# Oracle Database. Script is valid for 10g and 11g versions.
#
# chkconfig: 35 80 30
# description: Oracle Database startup script

# Source function library.

. /etc/rc.d/init.d/functions

ORACLE_OWNER=”oracle”
ORACLE_HOME=”/u01/app/oracle/product/11.1.0/db_1″

case “” in
start)
echo -n $ “Starting Oracle DB:”
su – $ ORACLE_OWNER -c “$ ORACLE_HOME/bin/dbstart $ ORACLE_HOME”
echo “OK”
;;
stop)
echo -n $ “Stopping Oracle DB:”
su – $ ORACLE_OWNER -c “$ ORACLE_HOME/bin/dbshut $ ORACLE_HOME”
echo “OK”
;;
*)
echo $ “Usage: {start|stop}”
esac
Execute (as root) following commands (First script change the permissions, second script is configuring execution for specific runlevels):
chmod 750 /etc/init.d/oracle
chkconfig –add oracle –level 0356
Auto Startup and Shutdown of Enterprise Manager Database Control
As root user create new file “oraemctl” (init script for startup and shutdown EM DB Console) in /etc/init.d/ directory with following content:
#!/bin/bash
#
# oraemctl Starting and stopping Oracle Enterprise Manager Database Control.
# Script is valid for 10g and 11g versions.
#
# chkconfig: 35 80 30
# description: Enterprise Manager DB Control startup script

# Source function library.

. /etc/rc.d/init.d/functions

ORACLE_OWNER=”oracle”
ORACLE_HOME=”/u01/app/oracle/product/11.1.0″

case “” in
start)
echo -n $ “Starting Oracle EM DB Console:”
su – $ ORACLE_OWNER -c “$ ORACLE_HOME/bin/emctl start dbconsole”
echo “OK”
;;
stop)
echo -n $ “Stopping Oracle EM DB Console:”
su – $ ORACLE_OWNER -c “$ ORACLE_HOME/bin/emctl stop dbconsole”
echo “OK”
;;
*)
echo $ “Usage: {start|stop}”
esac

# под root следующии команды 
# (первый скрипт меняет разрешения, второй настраивает исполнения для 
# определенных уровней выполнения)

chmod 750 /etc/init.d/oraemctl
chkconfig -add oraemctl -level 0356

# можна использовать rlwrap для удобной работы с утилитой sqlplus и adrci
# после того как скачаете RPM-пакет дистрибутив выполнить команду

su -
# rpm -ivh rlwrap-0.24-rh.i386.rpm
# exit
echo “alias sqlplus=’rlwrap sqlplus’” >> /home/oracle/.bash_profile
echo “alias adrci=’rlwrap adrci’” >> /home/oracle/.bash_profile
. /home/oracle/.bash_profile

# THE END!