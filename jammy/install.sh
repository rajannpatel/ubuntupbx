#!/bin/bash
# Ubuntu Pro token from: https://ubuntu.com/pro/dashboard (not needed for Ubuntu Pro instances on Azure, AWS, or Google Cloud)
TOKEN=''
FQDN=voip.example.com
HOSTNAME=voip
DOMAIN=example.com
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=username@gmail.com
SMTP_PASSWORD=yourpassword
PRETTY_HOSTNAME="My PBX Server"
sudo hostnamectl set-hostname "$FQDN" --static
sudo hostnamectl set-hostname "$FQDN" --transient
sudo hostnamectl set-hostname "$HOSTNAME"
sudo hostnamectl set-hostname "$PRETTY_HOSTNAME" --pretty
bash -c 'cat <<EOF > /etc/systemd/system/freepbx.service
[Unit]
Description=$PRETTY_HOSTNAME
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
echo "[$SMTP_HOST]:$SMTP_PORT $SMTP_USERNAME:$SMTP_PASSWORD" > /etc/postfix/sasl_passwd
if [[ -n "${SMTP_HOST}" ]]; then
  postconf -e myorigin="${DOMAIN}"
  postconf -e masquerade_domains="${DOMAIN}"
  postconf -e mydestination=localhost
  postconf -e smtp_sasl_tls_security_options=noanonymous
  postconf -e smtp_tls_security_level=encrypt
  postconf -e smtp_use_tls=yes
  postconf -e myhostname="${FQDN}"
  postconf -e mydomain="${DOMAIN}"
  postconf -e default_transport=smtp
  postconf -e relay_transport=smtp
  postconf -e relayhost="[$SMTP_HOST]:${SMTP_PORT}"
  postconf -e smtp_tls_security_level=encrypt
  postconf -e smtp_sasl_auth_enable=yes
  postconf -e smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd
  postconf -e header_size_limit=4096000
  postconf -e smtp_sasl_security_options=noanonymous
  postmap /etc/postfix/sasl_passwd
  rm /etc/postfix/sasl_passwd
  chmod 600 /etc/postfix/sasl_passwd.db
  systemctl restart postfix.service
fi
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
# Define the logrotate configuration
LOGROTATE_CONFIG="/etc/logrotate.d/asterisk"
CONFIG_CONTENT=$(cat <<EOF
/var/log/asterisk/debug /var/log/asterisk/messages /var/log/asterisk/full /var/log/asterisk/*_log {
    weekly
    missingok
    rotate 4
    sharedscripts
    postrotate
        /usr/sbin/invoke-rc.d asterisk logger-reload > /dev/null 2> /dev/null
    endscript
}
EOF
)

# Check if the logrotate configuration file already exists
if [ -e "$LOGROTATE_CONFIG" ]; then
    echo "Logrotate configuration for Asterisk already exists at $LOGROTATE_CONFIG"
else
    # Write the configuration to the file
    echo "$CONFIG_CONTENT" | sudo tee "$LOGROTATE_CONFIG" > /dev/null
    echo "Logrotate configuration added at $LOGROTATE_CONFIG"
fi

# Test the logrotate configuration
echo "Testing logrotate configuration..."
sudo logrotate -v -f "$LOGROTATE_CONFIG"

echo "Logrotate configuration completed!"

# crontab -l | { cat; echo "MAILTO="YOUREMAIL@GMAIL.COM"; } | crontab -
crontab -l | { cat; echo "@daily find /var/spool/asterisk/monitor -type f -size 44c -delete"; } | crontab -
crontab -l | { cat; echo "@daily find /var/spool/asterisk/monitor/*/*/*/ -type d -mtime +5 -exec rm -rf {} \; 2>/dev/null"; } | crontab -
crontab -l | { cat; echo "@daily find /var/spool/asterisk/monitor/*/ -type d -mtime +365 -exec rm -rf {} \; 2>/dev/null"; } | crontab -
crontab -l | { cat; echo "@daily find /var/spool/asterisk/voicemail -type f -name msg????.??? -mtime +45 -delete"; } | crontab -

reboot