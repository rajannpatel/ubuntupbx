#!/bin/bash
DOMAIN=rajanpatel.com
HOSTNAME=voip
# https://support.google.com/accounts/answer/185833?hl=en
GMAIL_USERNAME=youremail@gmail.com
GMAIL_PASSWORD=your_app_password
bash -c 'cat <<EOF > /etc/systemd/system/freepbx.service
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
DEBIAN_FRONTEND=noninteractive apt-get install -y php-{bcmath,cli,curl,gd,intl,ldap,mbstring,mysql,xml} apache2
curl -sL https://deb.nodesource.com/setup_12.x -o /tmp/nodesource_setup.sh
bash /tmp/nodesource_setup.sh
DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs npm
DEBIAN_FRONTEND=noninteractive apt-get install -y libapache2-mod-php
debconf-set-selections <<< "postfix postfix/mailname string $DOMAIN"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
DEBIAN_FRONTEND=noninteractive apt-get install -y postfix
DEBIAN_FRONTEND=noninteractive apt-get install -y curl dirmngr ffmpeg git lame libicu-dev mpg123 sqlite3 sox
# `/usr/src/asterisk-18*/contrib/scripts/install_prereq test` identifies these packages
DEBIAN_FRONTEND=noninteractive apt-get install -y bison doxygen flex graphviz libcfg-dev libcodec2-dev libcorosync-common-dev libcpg-dev libfftw3-dev libgmime-2.6-dev libjack-jackd2-dev liblua5.2-dev libneon27-dev libosptk-dev libsndfile1-dev pkgconf python-dev-is-python2 subversion xmlstarlet
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
fwconsole ma downloadinstall pm2 framework customappsreg featurecodeadmin recordings soundlang calendar callrecording conferences core ivr infoservices queues ringgroups timeconditions asteriskinfo cel voicemail sipsettings logfiles dashboard music filestore backup
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