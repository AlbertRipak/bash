#!/bin/bash
echo "Step 1: upgrade & update system"
dnf upgrade --refresh -y
dnf update

systemctl stop firewalld
systemctl disable firewalld

echo "Step 2: install repository"
rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/8/x86_64/zabbix-release-6.0-1.el8.noarch.rpm
dnf clean all

echo "Step 4: install mysql"
dnf module list mysql
dnf module enable mysql:8.0 -y
dnf install mysql-server -y
mysql --version
systemctl enable mysqld --now
systemctl start mysqld --now
grep "temporary password" /var/log/mysql/mysqld.log
mysql_secure_installation

echo "Step 5: install nginx"
dnf module list nginx
dnf module reset nginx -y
dnf module enable nginx:1.20
dnf install nginx -y
systemctl enable nginx
systemctl start nginx
ss -tulpn

echo "Step 6: install php"
echo "add repository"
dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y
dnf install dnf-utils http://rpms.remirepo.net/enterprise/remi-release-8.rpm
echo "remove old version"
dnf remove php php-fpm -y
dnf remove php* -y
echo "show list php"
dnf module list reset php -y
echo "select & install php"
dnf module enable php:remi-8.1 -y
#dnf install php -y #if you use apache  
dnf install php-fpm -y #if you use nginx
sed -i.bak 's/user = apache/user = nginx/' /etc/php-fpm.d/www.conf
sed -i 's/group = apache/group = nginx/' /etc/php-fpm.d/www.conf
systemctl restart php-fpm
echo "change configuration for nginx"
echo "location ~ \.php$ {
        try_files $uri =404;
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_index   index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
"
echo "Step 7: install zabbix"
dnf install zabbix-server-mysql zabbix-web-mysql zabbix-nginx-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent

zcat /usr/share/doc/zabbix-sql-scripts/mysql/server.sql.gz | mysql -uzabbix -p zabbix

echo "CHANGE PASSWORD /etc/zabbix/zabbix_server.conf"
#sed -i.bak 's/# DBPassword=/DBPassword=pQFM&8QMm6/' /etc/zabbix/zabbix_server.conf

echo "php_value[date.timezone] = Europe/Kiev" >> /etc/php-fpm.d/zabbix.conf

echo "configure nginx"
sed -i.bak 's/types_hash_max_size 4096;/types_hash_max_size 2048;/' /etc/nginx/nginx.conf

echo "Step  : Create initial database"

echo "
#mysql> create database zabbix character set utf8mb4 collate utf8mb4_bin;
#mysql> create user zabbix@localhost identified by 'password';
#mysql> grant all privileges on zabbix.* to zabbix@localhost;
#mysql> quit"

mysql -uroot -p

echo "Step : Add new language"
dnf install langpacks-uk -y #uk 	Ukrainian 
#dnf remove langpacks-uk

echo "Step 3: clean cache"
dnf clean all