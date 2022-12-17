#!/bin/bash
DOMAIN=rajanpatel.com
HOSTNAME=voip
GMAIL_USERNAME=rajannpatel@gmail.com
GMAIL_PASSWORD=mypassword
sudo bash -c 'cat <<EOF > /etc/systemd/system/freepbx.service
[Unit]
Description=FreePBX VoIP Server
After=mariadb.service
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/sbin/fwconsole start -q
ExecStop=/usr/sbin/fwconsole stop -q
[Install]
WantedBy=multi-user.target
EOF'
apt update
DEBIAN_FRONTEND=noninteractive apt upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server mariadb-client odbc-mariadb
DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common
add-apt-repository -y ppa:ondrej/php
DEBIAN_FRONTEND=noninteractive apt-get install -y php7.4-{bcmath,cli,curl,gd,intl,ldap,mbstring,mysql,xml} apache2 nodejs npm
DEBIAN_FRONTEND=noninteractive apt-get install -y libapache2-mod-php7.4
debconf-set-selections <<< "postfix postfix/mailname string $DOMAIN"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
DEBIAN_FRONTEND=noninteractive apt-get install -y postfix
DEBIAN_FRONTEND=noninteractive apt-get install -y curl dirmngr ffmpeg git lame libicu-dev mpg123 sqlite3 sox
# `/usr/src/asterisk-18*/contrib/scripts/install_prereq install` identifies these packages
DEBIAN_FRONTEND=noninteractive apt-get install -y bison doxygen flex graphviz libcfg-dev libcorosync-common-dev libcpg-dev libjack-jackd2-dev libldap2-dev libosptk-dev pkgconf subversion xmlstarlet
timedatectl set-timezone America/New_York
iptables -F && netfilter-persistent save
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
swapon -s
grep -qxF '/swapfile none swap sw 0 0' /etc/fstab || sed -i -e "\$a/swapfile none swap sw 0 0" /etc/fstab
# install asterisk
sed -i '/deb-src/s/^# //' /etc/apt/sources.list && apt update
DEBIAN_FRONTEND=noninteractive apt-get -y build-dep asterisk
cd /tmp && apt-get -y source asterisk && mv asterisk*/ /usr/src
# change path to asterisk folder with highest version number
cd "$(printf "%s"$'\n' /usr/src/asterisk* | sort -Vr | head -n1)"
make distclean
./configure --with-jansson-bundled
make menuselect.makeopts
menuselect/menuselect --enable app_macro --enable CORE-SOUNDS-EN-ULAW --enable MOH-OPSOUND-ULAW --enable EXTRA-SOUNDS-EN-ULAW --disable-category MENUSELECT_CDR --disable-category MENUSELECT_CEL --disable res_snmp --disable chan_dahdi menuselect.makeopts
adduser asterisk --disabled-password --gecos "Asterisk User"
make && make install && chown -R asterisk. /var/lib/asterisk
cd /usr/src
git clone -b release/16.0 --single-branch https://github.com/freepbx/framework.git freepbx
touch /etc/asterisk/modules.conf
cd /usr/src/freepbx
./start_asterisk start
./install -n
fwconsole ma downloadinstall customappsreg featurecodeadmin framework pm2 recordings soundlang calendar callrecording conferences core ivr infoservices queues ringgroups timeconditions asteriskinfo cel voicemail sipsettings logfiles dashboard music filestore backup
fwconsole chown
fwconsole reload
sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php/7.4/apache2/php.ini
sed -i 's/\(^memory_limit = \).*/\1256M/' /etc/php/7.4/apache2/php.ini
sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf
sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
a2enmod rewrite
systemctl restart apache2
rm /var/www/html/index.html
sed -i 's#Socket=/var/lib/mysql/mysql.sock#Socket=/var/run/mysqld/mysqld.sock#g' /etc/odbc.ini
fwconsole restart
systemctl daemon-reload
systemctl enable freepbx
reboot
