#!/bin/bash
# Ubuntu Pro token from: https://ubuntu.com/pro/dashboard (not needed for Ubuntu Pro instances on Azure, AWS, or Google Cloud)
TOKEN=''
DOMAIN=yourdomain.com
SENDGRID_API_KEY=your-api-key
GMAIL_USERNAME=username@gmail.com
GMAIL_PASSWORD=yourpassword
# toggle to decide if sendgrid or gmail configs will be applied
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
[ -n "$TOKEN" ] && pro attach $TOKEN && pro enable livepatch
DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server mariadb-client odbc-mariadb
DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common
add-apt-repository -y ppa:ondrej/php
DEBIAN_FRONTEND=noninteractive apt-get install -y php7.4-{bcmath,cli,curl,gd,intl,ldap,mbstring,mysql,xml} apache2 nodejs npm
DEBIAN_FRONTEND=noninteractive apt-get install -y libapache2-mod-php7.4
debconf-set-selections <<< "postfix postfix/mailname string $DOMAIN"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
DEBIAN_FRONTEND=noninteractive apt-get install -y postfix
# Configure server to send email via Sendgrid
echo $DOMAIN > /etc/mailname
# Check the length of the Sendgrid API Key, they have to be 69 characters
if [ ${#var} -eq 69 ]; then
# configure main.cf for sendgrid
sed -i.bak -E 's/^([ \t]*append_dot_mydomain[ \t]*=[ \t]*).*/\1'"yes"'/' /etc/postfix/main.cf
sed -i.bak -E 's/^([ \t]*myhostname[ \t]*=[ \t]*).*/\1'"$DOMAIN"'/' /etc/postfix/main.cf
sed -i.bak -E 's/^([ \t]*mydestination[ \t]*=[ \t]*).*/\1'"localhost"'/' /etc/postfix/main.cf
sed -i.bak -E 's/^([ \t]*relayhost[ \t]*=[ \t]*).*/\1'"[smtp.sendgrid.net]:2525"'/' /etc/postfix/main.cf
bash -c 'cat <<EOF >> /etc/postfix/main.cf
smtp_tls_security_level = encrypt
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
header_size_limit = 4096000
smtp_sasl_security_options = noanonymous
EOF'
# write the sendgrid API key to the sasl_passwd file
echo [smtp.sendgrid.net]:2525 apikey:$SENDGRID_API_KEY >> /etc/postfix/sasl_passwd
else
# Configure server to send email via Gmail
cat << EOF > /etc/postfix/main.cf
# Basic configuration
myhostname = $DOMAIN
myorigin = $DOMAIN
mydestination = localhost
relayhost = [smtp.gmail.com]:587
inet_interfaces = loopback-only

# Security configuration
smtp_sasl_auth_enable = yes
smtp_sasl_security_options = noanonymous
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_tls_security_level = encrypt
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
EOF
# Create the sasl_passwd file to store the Gmail login information
echo "[smtp.gmail.com]:587 username@gmail.com:password" > /etc/postfix/sasl_passwd
fi

# Use the postmap utility to generate a .db file, and set appropriate privileges
postmap /etc/postfix/sasl_passwd
chown root:root /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
chmod 600 /etc/postfix/sasl_passwd.db

# remove file containing credentials
rm /etc/postfix/sasl_passwd

# Reload your configuration to load the modified parameters:
/etc/init.d/postfix restart

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