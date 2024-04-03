IssabelPBX
==========

IssabelPBX is an opensource GUI (graphical user interface) that controls and manages Asterisk (PBX). 

IssabelPBX is derived/forked from FreePBX that was also forked/renamed from the original AMP released
on 2004 by Coalescent Systems Inc.

#### Environmental Variables:
Prior to running `install-issabel-debian.sh`, an `issabel_var.env` file must be created.  There is
a sample file, `issabel_var.env.sample` here which provides a template. The values are needed:

- **ASTERISK_URL_CERTIFIED**: It is the url to download asterisk certified version, by default the value
is https://downloads.asterisk.org/pub/telephony/certified-asterisk/releases

- **ASTERISK_URL**: It is the url to download asterisk version, the possible value are
for new version https://downloads.asterisk.org/pub/telephony/asterisk and old releases 
https://downloads.asterisk.org/pub/telephony/asterisk/old-releases

- **ASTERISK_SRC_FILE**: It is the source asterisk files that we are going to install.

  For get a list the asterisk certified version run:
```sh
curl -s https://downloads.asterisk.org/pub/telephony/certified-asterisk/releases/ | grep -Po '">\K.+.tar.gz' | grep -v "patch"`
```

  For new asterisk version run:
```sh
curl -s https://downloads.asterisk.org/pub/telephony/asterisk/ | grep -Po '">\K.+.tar.gz' | grep -v "patch"`
```

  For old releases asterisk version run:

```sh
curl -s https://downloads.asterisk.org/pub/telephony/asterisk/old-releases/ | grep -Po '">\K.+.tar.gz' | grep -Pv "patch|addons|sounds"
```

- **ISSABEL_ADMIN_PASSWORD**: It is the password for user 'admin' that will 
be used for: Issabel Web Login and IssabelPBX.

- **language**: This should be the English "en_EN" or Español "es_ES" 

- **ISSABLE_SETTINGS_TABLE**: It is the mysql table that contains the issabel setting. 
By default the values is: issabelpbx_settings

- **LETSENCRYPT_HTTPS_URL**: It is Domain that your associated with your public ip.

- **LETSENCRYPT_EMAIL**: This is your email for generate the certificate with 
letsencrypt.

- **HTTPSCERTFILE**: It is the location of the ssl certificate file
/etc/asterisk/keys/asterisk_cert_file.pem

- **HTTPSPRIVATEKEY**: It is the location of the ssl certificate private key file
/etc/asterisk/keys/asterisk_privkey.pem

Installation
------------

Clone repository

Fill issabel_var.env

Run
```sh
./install-issabel-debian.sh
```

Generates and config certifies
------------------------------ 

Run
```sh
./config_certificates.sh
```