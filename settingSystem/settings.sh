#!/bin/bash

echo "Step 1. Install epel-release."
yum -y install epel-release

echo "Step 2. Update."
yum -y update

echo "Step 3. Install mc package!"
yum -y install mc 
cp /usr/share/mc/syntax/sh.syntax /usr/share/mc/syntax/unknown.syntax

echo "Step 4. Disable firewalld."
sed -i.bak 's/=enforcing/=disabled/' /etc/sysconfig/selinux
setenforce 0
systemctl stop firewalld
systemctl disable firewalld

echo "Step 5: Install iptables and packages need oracle database sowtfare!"
yum -y install iptables binutils java \
		elfutils elfutils-libelf gcc gcc-c++ \
		glibc glibc-common glibc-devel cpp make \
		sysstat libaio libaio-devel unixODBC unixODBC-devel
yum install -y xorg-x11-server-Xorg xorg-x11-xauth xorg-x11* \
		xterm chrony iftop htop atop lsof wget bzip2 traceroute \
		gdisk unzip zip net-tools bind-utils

echo "Step 6: Config date!"
systemctl start chronyd
systemctl enable chronyd
timedatectl set-timezone Europe/Kiev

yum -y install iptables-services

echo "Step 7: Create and configure file iptables.sh!"
echo '
#!/bin/bash
#
# Объявление переменных
export IPT="iptables"

# Интерфейс который смотрит в интернет
export WAN=eth0
export WAN_IP=YOUR_IP_ADDRESS
export LAN=eth1
export LAN_IP=YOUR_IP_ADDRESS

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

echo "Step 8: Substutute port for ssh on 55555!"
#sed -i.bak 's/#Port 22/Port 55555/' /etc/ssh/sshd_config

echo "Step 9: Setting history comand!"

echo "export HISTSIZE=10000
export HISTTIMEFORMAT=\"%h %d %H:%M:%S \"
PROMPT_COMMAND='history -a'
export HISTIGNORE=\"ls:ll:history:w:\"" >> /root/.bashrc

echo "Step 10: Install nginx"
yum -y install nginx
systemctl enable nginx
systemctl start nginx

echo "Step 12: Configure nginx."
mkdir -p /var/www/$HOSTNAME/html
sudo chown -R $USER:$USER	/var/www/$HOSTNAME

echo "Step 13: Confgiure vimrc."
yum -y install vim

echo ' 
" ~/.vimrc

" Отступы и нумерация строк
" переменная expandtab - заменяет табы на пробелы
set expandtab

" smarttab - при нажатии таба в начале строки доавляет количество пробелов
" равное shiftwidth
set smarttab

" tabstop - количество пробелов в одном обычном tab
set tabstop=4

" softtabtstop - количество пробелов в табе при удfлении
set softtabstop=4

" shiftwidth - количество пробелов
set shiftwidth=4

" number - нумерация срок
set number

" foldcolumn - отступы между левой частью окна
set foldcolumn=2

" colorscheme - цветовая схема
colorscheme darkblue

" syntax on - включает подсветку синтаксиса
syntax on

" отключаем звук при нажатии не той кнопки
set noerrorbells
set novisualbell

" set mouse=a - поддержка миши в граф. интерф.
set mouse=a

" Смотрим поддерживает ли vim работу с системным буфером обмена
" vim --version | grep clipboard
" Если есть +clipboard всё хорошо

" Настройка поиска 
" игнорируем регистр
set ignorecase
set smartcase

" подсвечивать результат поиска 
set hlsearch

" что бы програма подсказала первое вхождиние поиска
set incsearch

" кодировка
set encoding=utf8
' >> ~/.vimrc