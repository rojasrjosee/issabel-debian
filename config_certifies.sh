#!/bin/bash

apt install -y cron 

SOURCE_DIR_SCRIPT=$(pwd)

[[ -s issabel_var.env ]] || {
   echo "Please create y complete file issabel_var.env"
   exit 1
}
source issabel_var.env
DNS_ADDRRESS=$(nslookup $LETSENCRYPT_HTTPS_URL | grep -Po "Address: \K.+")
PUBLIC_IP_ADDRESS=$(curl -s -4 ip.me)

[[ "$DNS_ADDRRESS" != "$PUBLIC_IP_ADDRESS" ]] && {
   echo -e ""
   echo -e "The url: $LETSENCRYPT_HTTPS_URL not resolve $PUBLIC_IP_ADDRESS"
   echo -e "Update or associate $LETSENCRYPT_HTTPS_URL with $PUBLIC_IP_ADDRESS"
   echo -e "Run again script\n"
   exit 1
}

grep -q "ServerName $LETSENCRYPT_HTTPS_URL" /etc/apache2/sites-available/000-default.conf || sed -Ei "s/(<VirtualHost \*\:80>)/\1\n        ServerName $LETSENCRYPT_HTTPS_URL\n        ServerAlias $LETSENCRYPT_HTTPS_URL\n/" /etc/apache2/sites-available/000-default.conf

if [ -z "${LETSENCRYPT_EMAIL}" ]; then
   echo -e ""
   echo -e "Please fill LETSENCRYPT_EMAIL var in issabel_var.env file"
   echo -e "Run again script\n"
   exit 1
fi

certbot certificates -d $LETSENCRYPT_HTTPS_URL 2>&1 | grep -q "VALID"  || {
   certbot --apache --non-interactive --agree-tos -d $LETSENCRYPT_HTTPS_URL -m $LETSENCRYPT_EMAIL
}

certbot certificates -d $LETSENCRYPT_HTTPS_URL 2>&1 | grep -q "VALID"  && {
   CERTFILE=$(readlink -e $(certbot certificates -d $LETSENCRYPT_HTTPS_URL 2>&1 | grep -Po "Certificate Path: \K.+"))
   PRIVATE_KEY=$(readlink -e $(certbot certificates -d $LETSENCRYPT_HTTPS_URL 2>&1 | grep -Po "Private Key Path: \K.+"))
   rm -rf $HTTPSCERTFILE
   rm -rf $HTTPSPRIVATEKEY
   /usr/bin/cp -rf $CERTFILE $HTTPSCERTFILE
   /usr/bin/cp -rf $PRIVATE_KEY $HTTPSPRIVATEKEY
   chown asterisk: $HTTPSCERTFILE $HTTPSPRIVATEKEY
   chmod 400 $HTTPSCERTFILE $HTTPSPRIVATEKEY 
   mysql asterisk -e "update issabelpbx_settings set value='$HTTPSCERTFILE' where keyword='HTTPSCERTFILE';"
   mysql asterisk -e "update issabelpbx_settings set value='$HTTPSPRIVATEKEY' where keyword='HTTPSPRIVATEKEY';"
   su -c "/var/lib/asterisk/bin/module_admin reload" -s /bin/bash asterisk
   /usr/sbin/asterisk -rx 'core restart now'
   cat > /usr/bin/asterisk_reload_certifies.sh <<EOF
#!/bin/bash

LETSENCRYPT_HTTPS_URL=$LETSENCRYPT_HTTPS_URL
HTTPSCERTFILE=$HTTPSCERTFILE
HTTPSPRIVATEKEY=$HTTPSPRIVATEKEY

CERTFILE=\$(readlink -e \$(certbot certificates -d $LETSENCRYPT_HTTPS_URL 2>&1 | grep -Po "Certificate Path: \K.+"))
PRIVATE_KEY=\$(readlink -e \$(certbot certificates -d $LETSENCRYPT_HTTPS_URL 2>&1 | grep -Po "Private Key Path: \K.+"))

rm -rf \$HTTPSCERTFILE
rm -rf \$HTTPSPRIVATEKEY

/usr/bin/cp -rf \$CERTFILE \$HTTPSCERTFILE
/usr/bin/cp -rf \$PRIVATE_KEY \$HTTPSPRIVATEKEY

/usr/bin/chown asterisk: \$HTTPSCERTFILE \$HTTPSPRIVATEKEY
/usr/sbin/asterisk -rx 'core restart now'
EOF
   chmod 755 /usr/bin/asterisk_reload_certifies.sh
   crontab -l  | grep -q "/usr/bin/certbot" || {
      crontab -l | { cat; echo '30 3 * * * /usr/bin/certbot renew --quiet --no-self-upgrade --post-hook "/usr/bin/asterisk_reload_certifies.sh"'; } | crontab -
   } 
}
