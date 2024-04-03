#!/bin/bash

SOURCE_DIR_SCRIPT=$(pwd)

[[ -s issabel_var.env ]] || {
   echo "Please create y complete file issabel_var.env"
   exit 1
}
source issabel_var.env

#Add sbin to path
if ! grep -Pq "export PATH=$PATH:/usr/local/sbin:/usr/sbin" "/etc/bash.bashrc"; then
   echo "export PATH=$PATH:/usr/local/sbin:/usr/sbin" >> /etc/bash.bashrc
fi

if ! $(echo "$PATH" | grep -Fq "sbin") ; then
   echo -e "Error: /usr/sbin is not in PATH\n"
   echo -e "Run: source /etc/bash.bashrc \n"
   echo -e "and run ./install-issabel-debian.sh\n"
   exit 1
fi


# Enable non free and contrib repos
sed -i -E 's/^(deb.+)main(.+)/\1main contrib non-free\2/g' /etc/apt/sources.list

#Updata and upgrade package
apt update
apt upgrade -y
apt install -y apt-transport-https lsb-release ca-certificates wget curl aptitude

#Uninstall apparmor
if service --status-all | grep -Fq 'apparmor'; then
   systemctl stop apparmor
   apt remove -y apparmor
fi

#Package installation
apt install -y \
   git apache2 gettext sngrep\
   unixodbc odbcinst unixodbc-dev \
   mariadb-server mariadb-client \
   libmariadb-dev cockpit net-tools \
   dialog locales-all libwww-perl \
   mpg123 fail2ban  \
   cracklib-runtime dnsutils \
   certbot python3-certbot-apache

#Add user asterisk
if ! id -u "asterisk" >/dev/null 2>&1; then
   adduser asterisk --uid 5000 --gecos "Asterisk PBX" --disabled-password --disabled-login --home /var/lib/asterisk
fi

#Download Asterisk
ASTERISK_DIR="${ASTERISK_SRC_FILE%%.*}"
ASTERISK_URL_DOWNLOAD=$ASTERISK_URL/$ASTERISK_SRC_FILE
if echo "$ASTERISK_SRC_FILE" | grep -Fq "certified" ; then
   ASTERISK_URL_DOWNLOAD=$ASTERISK_URL_CERTIFIED/$ASTERISK_SRC_FILE
fi


cd /usr/src
wget $ASTERISK_URL_DOWNLOAD

tar zxvf $ASTERISK_SRC_FILE

cd ${ASTERISK_DIR}*/

#Install Asterisk dependencies
contrib/scripts/install_prereq install

#Install asterisk
./configure
make menuselect.makeopts 
menuselect/menuselect \
    --disable-category MENUSELECT_ADDONS \
    --disable app_flash \
    --disable app_skel \
    --disable-category MENUSELECT_CDR \
    --disable-category MENUSELECT_CEL \
    --disable cdr_pgsql \
    --disable cel_pgsql \
    --enable cdr_adaptive_odbc \
    --enable cel_odbc \
    --disable-category MENUSELECT_CHANNELS \
    --enable  chan_iax2 \
    --enable  chan_pjsip \
    --enable  chan_rtp \
    --enable-category MENUSELECT_CODECS \
    --enable-category MENUSELECT_FORMATS \
    --enable-category MENUSELECT_FUNCS \
    --enable-category  MENUSELECT_PBX \
    --enable  pbx_config \
    --enable pbx_loopback \
    --enable pbx_spool \
    --enable pbx_realtime \
    --enable res_agi \
    --enable res_ari \
    --enable res_ari_applications \
    --enable res_ari_asterisk \
    --enable res_ari_bridges \
    --enable res_ari_channels \
    --enable res_ari_device_states \
    --enable res_ari_endpoints \
    --enable res_ari_events \
    --enable res_ari_mailboxes \
    --enable res_ari_model \
    --enable res_ari_playbacks \
    --enable res_ari_recordings \
    --enable res_ari_sounds \
    --enable res_clialiases \
    --enable res_clioriginate \
    --enable res_config_curl \
    --enable res_config_odbc \
    --disable res_config_sqlite3 \
    --enable res_convert \
    --enable res_crypto \
    --enable res_curl \
    --enable res_fax \
    --enable res_format_attr_celt \
    --enable res_format_attr_g729 \
    --enable res_format_attr_h263 \
    --enable res_format_attr_h264 \
    --enable res_format_attr_ilbc \
    --enable res_format_attr_opus \
    --enable res_format_attr_silk \
    --enable res_format_attr_siren14 \
    --enable res_format_attr_siren7 \
    --enable res_format_attr_vp8 \
    --enable res_http_media_cache \
    --enable res_http_post \
    --enable res_http_websocket \
    --enable res_limit \
    --enable res_manager_devicestate \
    --enable res_manager_presencestate \
    --enable res_musiconhold \
    --enable res_mutestream \
    --enable res_mwi_devstate \
    --disable res_mwi_external \
    --disable res_mwi_external_ami \
    --disable res_odbc \
    --disable res_odbc_transaction \
    --enable res_parking \
    --enable res_pjproject \
    --enable res_pjsip \
    --enable res_pjsip_acl \
    --enable res_pjsip_authenticator_digest \
    --enable res_pjsip_caller_id \
    --enable res_pjsip_config_wizard \
    --enable res_pjsip_dialog_info_body_generator \
    --enable res_pjsip_diversion \
    --enable res_pjsip_dlg_options \
    --enable res_pjsip_dtmf_info \
    --enable res_pjsip_empty_info \
    --enable res_pjsip_endpoint_identifier_anonymous \
    --enable res_pjsip_endpoint_identifier_ip \
    --enable res_pjsip_endpoint_identifier_user \
    --enable res_pjsip_exten_state \
    --enable res_pjsip_header_funcs \
    --enable res_pjsip_logger \
    --enable res_pjsip_messaging \
    --enable res_pjsip_mwi \
    --enable res_pjsip_mwi_body_generator \
    --enable res_pjsip_nat \
    --enable res_pjsip_notify \
    --enable res_pjsip_one_touch_record_info \
    --enable res_pjsip_outbound_authenticator_digest \
    --enable res_pjsip_outbound_publish \
    --enable res_pjsip_outbound_registration \
    --enable res_pjsip_path \
    --enable res_pjsip_pidf_body_generator \
    --enable res_pjsip_pidf_digium_body_supplement \
    --enable res_pjsip_pidf_eyebeam_body_supplement \
    --enable res_pjsip_publish_asterisk \
    --enable res_pjsip_pubsub \
    --enable res_pjsip_refer \
    --enable res_pjsip_registrar \
    --enable res_pjsip_rfc3326 \
    --enable res_pjsip_sdp_rtp \
    --enable res_pjsip_send_to_voicemail \
    --enable res_pjsip_session \
    --enable res_pjsip_sips_contact \
    --enable res_pjsip_t38 \
    --enable res_pjsip_transport_websocket \
    --enable res_pjsip_xpidf_body_generator \
    --enable res_realtime \
    --enable res_resolver_unbound \
    --enable res_rtp_asterisk \
    --enable res_rtp_multicast \
    --enable res_security_log \
    --enable res_sorcery_astdb \
    --enable res_sorcery_config \
    --enable res_sorcery_memory \
    --enable res_sorcery_memory_cache \
    --enable res_sorcery_realtime \
    --enable res_speech \
    --enable res_srtp \
    --enable res_stasis \
    --enable res_stasis_answer \
    --enable res_stasis_device_state \
    --enable res_stasis_mailbox \
    --enable res_stasis_playback \
    --enable res_stasis_recording \
    --enable res_stasis_snoop \
    --enable res_stasis_test \
    --enable res_stun_monitor \
    --enable res_timing_dahdi \
    --enable res_timing_timerfd \
    --disable res_ael_share \
    --disable res_calendar \
    --disable res_calendar_caldav \
    --disable res_calendar_ews \
    --disable res_calendar_exchange \
    --disable res_calendar_icalendar \
    --disable res_chan_stats \
    --disable res_config_ldap \
    --enable res_config_pgsql \
    --disable res_corosync \
    --disable res_endpoint_stats \
    --disable res_fax_spandsp \
    --enable res_hep \
    --enable res_hep_pjsip \
    --enable res_hep_rtcp \
    --disable res_phoneprov \
    --disable res_pjsip_history \
    --disable res_pjsip_phoneprov_provider \
    --disable res_pktccops \
    --disable res_remb_modifier \
    --disable res_smdi \
    --disable res_snmp \
    --disable res_statsd \
    --enable res_timing_kqueue \
    --disable res_timing_pthread \
    --disable res_adsi \
    --enable res_config_sqlite3 \
    --disable res_monitor \
    --disable res_digium_phone \
    --disable res_mwi_external \
    --disable res_stasis_mailbox \
    menuselect.makeopts

make
make install

#Asterisk service systemd
cat > /lib/systemd/system/asterisk.service <<EOF
[Unit]
Description=LSB: Asterisk PBX
Before=runlevel2.target
Before=runlevel3.target
Before=runlevel4.target
Before=runlevel5.target
Before=shutdown.target
#Before=iaxmodem.service
#Before=issabel-updaterd.service
#Before=issabel-portknock.service
After=network-online.target
After=nss-lookup.target
After=remote-fs.target
#After=dahdi.service
#After=misdn.service
#After=lcr.service
#After=wanrouter.service
#After=mysql.service
After=postgresql.service
After=network-online.target
Wants=network-online.target
Conflicts=shutdown.target

[Service]
Type=simple
Environment=HOME=/var/lib/asterisk
WorkingDirectory=/var/lib/asterisk
ExecStart=/usr/sbin/asterisk -U asterisk -G asterisk -mqf -C /etc/asterisk/asterisk.conf
#ExecStart=/usr/sbin/asterisk -f -C /etc/asterisk/asterisk.conf -vvvg
ExecReload=/usr/sbin/asterisk -rx 'core reload'
LimitCORE=infinity
LimitNOFILE=infinity
LimitNPROC=infinity
LimitMEMLOCK=infinity
Restart=on-failure
RestartSec=4
# Prevent duplication of logs with color codes to /var/log/messages
StandardOutput=null
PrivateTmp=true

#Nice=0
#UMask=0002
#LimitNOFILE=

[Install]
WantedBy=multi-user.target
EOF

tar zxvf $SOURCE_DIR_SCRIPT/asterisk_issabel.tar.gz -C /etc
rm -f /etc/asteris/stir_shaken.conf

#Set permisions to asterisk directories
chown -R asterisk: /etc/asterisk/
chown -R asterisk: /var/run/asterisk
chown -R asterisk: /var/log/asterisk
chown -R asterisk: /var/lib/asterisk

#Start asterisk
systemctl enable asterisk.service
systemctl start asterisk.service

cat > /var/lib/asterisk/agi-bin/login-info.sh <<EOF
#!/bin/bash
exec 2>&1
user=$(whoami)
load=`cat /proc/loadavg | awk '{print $1" (1min) "$2" (5min) "$3" (15min)"}'`
memory_usage=`free -m | awk '/Mem:/ { printf("%3.0f%%", ($3/$2)*100)}'`
memory=`free -m | awk '/Mem:/ { print $2 }'`
mem_used=`free -m| grep ^Mem | awk '{print $3}'`
swap_usage=`free -m | awk '/Swap/ { printf("%3.1f%%", "exit !$2;$3/$2*100") }'`
users=` w -s | grep -v WHAT | grep -v "load average" | wc -l`
time=`uptime | grep -ohe 'up .*' | sed 's/,/\ hours/g' | awk '{ printf $2" "$3 }'`
processes_total=`ps aux | wc -l`
processes_user=`ps -U ${user} u | wc -l`

root_total=`df -h / | awk '/\// {print $(NF-4)}'`
root_usedgb=`df -h / | awk '/\// {print $(NF-3)}' | sed 's/[^0-9\.,]//'`
root_used=`df -h / | awk '/\// {print $(NF-1)}' | sed 's/[^0-9]//'`
root_used_print=$(printf "%3.0f%%" $root_used)
root_free=$(expr 100 - $root_used)
root_used_gauge_val=`awk "BEGIN { a=($root_used/2); printf(\"%0.f\",a)}"`
root_free_gauge_val=`awk "BEGIN { a=($root_free/2); printf(\"%0.f\",a)}"`
root_used_gauge=$(seq -s= $root_used_gauge_val|tr -d '[:digit:]')
root_free_gauge=$(seq -s- $root_free_gauge_val|tr -d '[:digit:]')
root_disk_gauge=$(echo "[$root_used_gauge>$root_free_gauge] $root_used_print")

mem_free=$(expr $memory - $mem_used)
mem_free_percent=`awk "BEGIN { a=($mem_free*100/$memory); printf(\"%0.f\",a)}"`
mem_used_percent=`awk "BEGIN { a=($mem_used*100/$memory); printf(\"%0.f\",a)}"`
mem_used_gauge_val=`awk "BEGIN { a=($mem_used_percent/2); printf(\"%0.f\",a)}"`
mem_free_gauge_val=`awk "BEGIN { a=($mem_free_percent/2); printf(\"%0.f\",a)}"`
mem_used_gauge=$(seq -s= $mem_used_gauge_val|tr -d '[:digit:]')
mem_free_gauge=$(seq -s- $mem_free_gauge_val|tr -d '[:digit:]')
mem_gauge=$(echo "[$mem_used_gauge>$mem_free_gauge] $memory_usage")

asterisk_version=`/usr/sbin/asterisk -V  2>/dev/null| awk '{print  $1" "$2}'`
asterisk_calls=`asterisk -rx "core show channels"  2>/dev/null | grep "active calls" | awk '{print $1}'`

printf "\033[1;35mSystem load: \033[1;32m %-43s \033[1;35mUptime:  \033[1;32m%s\n" "$load" "$time"
if [ -z "$asterisk_version" ]; then
echo -e "\033[1;35mAsterisk:     \033[33;5mOFFLINE\033[0m"
else
printf "\033[1;35mAsterisk:    \033[1;32m %-37s \033[1;35mActive Calls: \033[1;32m %s\n" "$asterisk_version" "$asterisk_calls"
fi
printf "\033[1;35mMemory:      \033[1;32m %s %s/%sM\n" "$mem_gauge" "$mem_used" "$memory" 
printf "\033[1;35mUsage on /:  \033[1;32m %s %s/%s\n" "$root_disk_gauge" "$root_usedgb" "$root_total" 
printf "\033[1;35mSwap usage:  \033[1;32m %s\n" "$swap_usage"
printf "\033[1;35mSSH logins:  \033[1;32m %d open sessions\n" "$users"
printf "\033[1;35mProcesses:   \033[1;32m %d total, %d yours\n" "$processes_total" "$processes_user"
printf "\e[m\n";
EOF

chmod 755 /var/lib/asterisk/agi-bin/login-info.sh
/usr/bin/cp -rf /var/lib/asterisk/agi-bin/login-info.sh /etc/profile.d/login-info.sh 

#Intall php7.4
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list 

apt update
apt-mark hold php8*
.
apt install -y \
   libapache2-mod-php7.4 php7.4-cli php7.4-common \
   php7.4-curl php7.4-json php7.4-mbstring \
   php7.4-mysql php7.4-opcache php7.4-readline \
   php7.4-sqlite3 php7.4-xml php7.4 php-pear

if [ -d /usr/lib/x86_64-linux-gnu/asterisk/modules ]; then
    mkdir /usr/lib/asterisk  
    ln -s /usr/lib/x86_64-linux-gnu/asterisk/modules /usr/lib/asterisk  
fi


# Redirect to /admin for web root
if [ -f /var/www/html/index.html ]; then
    mv /var/www/html/index.html /var/www/html/index.html.bak  
fi

cat > /var/www/html/index.html <<EOF
<html>
<head>
<meta http-equiv="refresh" content="0; url=/admin">
</head>
<body></body>
</html>
EOF

# Apache Configuration
sed -i -e "s/www-data/asterisk/" /etc/apache2/envvars
echo "<Directory /var/www/html/pbxapi>" >/etc/apache2/conf-available/pbxapi.conf
echo "    AllowOverride All" >>/etc/apache2/conf-available/pbxapi.conf
echo "</Directory>" >>/etc/apache2/conf-available/pbxapi.conf
ln -s /etc/apache2/conf-available/pbxapi.conf /etc/apache2/conf-enabled  
a2enmod rewrite 

# Enable SSL
a2enmod ssl  
ln -s /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-enabled/  

#Restart apache
systemctl restart apache2  


# UnixODBC config

cat > /etc/odbc.ini <<EOF
[MySQL-asteriskcdrdb]
Description=MySQL connection to 'asteriskcdrdb' database
driver=MySQL ODBC 8.0 Unicode Driver
server=localhost
database=asteriskcdrdb
Port=3306
Socket=/var/lib/mysql/mysql.sock
option=3
Charset=utf8

[asterisk]
driver=MySQL ODBC 8.0 Unicode Driver
server=localhost
database=asterisk
Port=3306
Socket=/var/lib/mysql/mysql.sock
option=3
charset=utf8
EOF


# Install Maria ODBC Connector for some distros/versions

cd /usr/src
if [ -e "/run/mysqld/mysqld.sock" ]; then
	sed -i -e 's/Socket=\/var\/lib\/mysql\/mysql.sock/astdatadir => \/run\/mysqld\/mysqld.sock/' /etc/odbc.ini
elif [ -e "/var/run/mysqld/mysqld.sock" ]; then
	sed -i -e 's/Socket=\/var\/lib\/mysql\/mysql.sock/astdatadir => \/var\/lib\/mysql\/mysql.sock/' /etc/odbc.ini
fi

if [ -f /etc/lsb-release ]; then
    DLFILE="https://dlm.mariadb.com/1936476/Connectors/odbc/connector-odbc-3.1.15/mariadb-connector-odbc-3.1.15-ubuntu-focal-amd64.tar.gz"
elif [ -f /etc/debian_version ]; then
    if [ $(cat /etc/debian_version | cut -d. -f1) = 12 ]; then
        DLFILE="https://dlm.mariadb.com/1936451/Connectors/odbc/connector-odbc-3.1.15/mariadb-connector-odbc-3.1.15-debian-buster-amd64.tar.gz"
    elif [ $(cat /etc/debian_version | cut -d. -f1) = 11 ]; then
        DLFILE="https://dlm.mariadb.com/1936451/Connectors/odbc/connector-odbc-3.1.15/mariadb-connector-odbc-3.1.15-debian-buster-amd64.tar.gz"
    elif [ $(cat /etc/debian_version | cut -d. -f1) = 10 ]; then
        DLFILE="https://dlm.mariadb.com/1936451/Connectors/odbc/connector-odbc-3.1.15/mariadb-connector-odbc-3.1.15-debian-buster-amd64.tar.gz"
    elif [ $(cat /etc/debian_version | cut -d. -f1) = 9 ]; then
	DLFILE="https://dlm.mariadb.com/1936481/Connectors/odbc/connector-odbc-3.1.15/mariadb-connector-odbc-3.1.15-debian-9-stretch-amd64.tar.gz"
    fi
fi

FILENAME=$(basename $DLFILE)
rm $FILENAME 
wget $DLFILE  
tar zxvf $FILENAME 
rm $FILENAME$A 
cp $(find /usr/src/ -name libmaodbc.so) /usr/local/lib 

cat > /etc/odbcinst.ini <<EOF
[MySQL ODBC 8.0 Unicode Driver]
Driver=/usr/local/lib/libmaodbc.so
UsageCount=1

[MySQL ODBC 8.0 ANSI Driver]
Driver=/usr/local/lib/libmaodbc.so
UsageCount=1
EOF

# IssabelPBX Installation
cd /usr/src
git clone https://github.com/asternic/issabelPBX.git

# IssabelPbx copy patch 
cp $SOURCE_DIR_SCRIPT/install_amp.patch issabelPBX
cp $SOURCE_DIR_SCRIPT/functions_inc.patch issabelPBX

# IssabelPbx apply patch 
cd /usr/src/issabelPBX/

git apply install_amp.patch
git apply functions_inc.patch

# Asterisk configs
sed -i '/^displayconnects/a #include manager_general_additional.conf' /etc/asterisk/manager.conf
sed -i '/^displayconnects/d' /etc/asterisk/manager.conf
touch /etc/asterisk/manager_general_additional.conf 
echo "displayconnects=yes" >/etc/asterisk/manager_general_additional.conf
echo "timestampevents=yes" >>/etc/asterisk/manager_general_additional.conf
echo "webenabled=no" >>/etc/asterisk/manager_general_additional.conf
chown asterisk.asterisk /etc/asterisk/manager_general_additional.conf 
chown asterisk.asterisk /usr/share/asterisk/agi-bin -R 
chown asterisk.asterisk /var/lib/asterisk/agi-bin -R 

# Install PearDB
pear install DB 

# fail2ban config
sed -i 's:/var/log/asterisk/messages:/var/log/asterisk/security:' /etc/fail2ban/jail.conf

if [ ! -f /etc/fail2ban/jail.d/issabelpbx.conf ]; then

cat <<'EOF' >/etc/fail2ban/jail.d/issabelpbx.conf
[asterisk]
enabled=true

[issabelpbx-auth]
enabled=true
logpath=/var/log/asterisk/issabelpbx.log
maxretry=3
bantime=43200
ignoreip=127.0.0.1
port=80,443
EOF

cat <<'EOF' >/etc/fail2ban/filter.d/issabelpbx-auth.conf
# Fail2Ban filter for issabelpbx
#
[INCLUDES]
before = common.conf
[Definition]
failregex = ^%(__prefix_line)s\[SECURITY\].+Invalid Login.+ <HOST>\s*$
ignoreregex =
EOF

fi

# Install spanish prompts
wget repo.issabel.org/azure_es_female.tgz  
tar zxvf azure_es_female.tgz -C /var/lib/asterisk/sounds/es

# If for some reason we do not have language set, default to english
if [ "$LANGUAGE" == "" ]; then
    LANGUAGE=en_EN
fi

if [ -z "${ISSABEL_ADMIN_PASSWORD}" ]; then
   ISSABEL_ADMIN_PASSWORD=XYZADMINadmin1234
fi

# Compile issabelPBX language files
cd /usr/src/issabelPBX/
build/compile_gettext.sh 
systemctl restart apache2 

# Install IssabelPBX with install_amp
framework/install_amp --dbuser=root --installdb --scripted --language=$LANGUAGE --adminpass=$ISSABEL_ADMIN_PASSWORD

systemctl restart fail2ban 
