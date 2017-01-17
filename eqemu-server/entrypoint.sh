#!/bin/bash

echo "Setting up server config"

# Set mysql default options
echo "[client]
host=\"$EQ_MYSQL_DB_HOST\"
user=\"$EQ_MYSQL_USER\"
password=\"$EQ_MYSQL_PASSWORD\"
database=\"$EQ_MYSQL_DATABASE\"" >> /etc/mysql/conf.d/eqemu.cnf

# Replace runtime config variables
sed -i -e "s/EQ_SERVER_SHORT_NAME/$EQ_SERVER_SHORT_NAME/g" /root/server/eqemu_config.xml
sed -i -e "s/EQ_SERVER_LONG_NAME/$EQ_SERVER_LONG_NAME/g" /root/server/eqemu_config.xml
sed -i -e "s/EQ_SERVER_KEY/$EQ_SERVER_KEY/g" /root/server/eqemu_config.xml
sed -i -e "s/EQ_LOGIN_SERVER/$EQ_LOGIN_SERVER/g" /root/server/eqemu_config.xml
sed -i -e "s/EQ_CHAT_SERVER/$EQ_CHAT_SERVER/g" /root/server/eqemu_config.xml
sed -i -e "s/EQ_SERVER_ADMIN_USERNAME/$EQ_SERVER_ADMIN_USERNAME/g" /root/server/eqemu_config.xml
sed -i -e "s/EQ_SERVER_ADMIN_PASSWORD/$EQ_SERVER_ADMIN_PASSWORD/g" /root/server/eqemu_config.xml
sed -i -e "s/EQ_MYSQL_DB_HOST/$EQ_MYSQL_DB_HOST/g" /root/server/eqemu_config.xml
sed -i -e "s/EQ_MYSQL_PASSWORD/$EQ_MYSQL_PASSWORD/g" /root/server/eqemu_config.xml

# Copy config
cp /root/eqemu/loginserver/login_util/login.ini /root/server/login.ini
sed -i -r "s/host = localhost/host = $EQ_MYSQL_DB_HOST/g" /root/server/login.ini
sed -i -r "s/db = eqemu/db = eq/g" /root/server/login.ini
sed -i -r "s/user = user/user = eq/g" /root/server/login.ini
sed -i -r "s/password = password/password = $EQ_MYSQL_PASSWORD/g" /root/server/login.ini

# Wait for mysql
until mysql -e 'show tables ;' &> /dev/null
do
  sleep 1
done

# Init db if it doesn't exist yet
if [ -z "`mysql -e 'show tables;'`" ] ; then
  echo "Initiatlizing Database $EQ_MYSQL_DATABASE"

  # Setup database
  mysql < /root/peq/peqbeta*.sql
  mysql < /root/peq/player*.sql

  # Setup login server
  cp /root/eqemu/loginserver/login_util/EQEmuLoginServerDBInstall.sql /tmp/EQEmuLoginServerDBInstall.sql
  # Remove default admin and server creation
  sed -i -r "s/INSERT INTO tblLoginServerAccounts.+$//gI" /tmp/EQEmuLoginServerDBInstall.sql
  sed -i -r "s/INSERT INTO tblServerAdminRegistration.+$//gI" /tmp/EQEmuLoginServerDBInstall.sql
  sed -i -r "s/INSERT INTO tblWorldServerRegistration.+$//gI" /tmp/EQEmuLoginServerDBInstall.sql
  mysql < /tmp/EQEmuLoginServerDBInstall.sql

  # Add server admin
  mysql -e "insert into tblServerAdminRegistration (Accountname,AccountPassword,FirstName,LastName,Email,RegistrationDate,RegistrationIPAddr) values ('$EQ_SERVER_ADMIN_USERNAME','$EQ_SERVER_ADMIN_PASSWORD','Server','Admin','srvadmin@dev.null',now(),'127.0.0.1');"

  # Register server with admin ID
  mysql -e "insert into tblWorldServerRegistration (ServerID,ServerLongName,ServerTagDescription,ServerShortName,ServerListTypeID,ServerLastLoginDate,ServerLastIPAddr,ServerAdminID,Note,ServerTrusted) values ('1','$EQ_SERVER_LONG_NAME','EQEMU','$EQ_SERVER_SHORT_NAME','1',now(),'127.0.0.1','1','','1');"

  # Create user login
  mysql -e "insert into tblLoginServerAccounts (AccountName, AccountPassword, AccountEmail, LastLoginDate, LastIPAddress) values('$EQ_SERVER_ADMIN_USERNAME', sha('$EQ_SERVER_ADMIN_PASSWORD'), 'admin@somewhere.com', now(), '127.0.0.1');"

  # TODO: this needs to happen after first login
  # cd /root/server
  # /root/server/world flag $EQ_SERVER_ADMIN_USERNAME 250
else
  echo "Database $EQ_MYSQL_DATABASE with tables found, skipping initialization"
fi

if [ -n "$PEQEDITOR_PORT" ]
then
  # Enable peqeditor
  echo "Enabling peqeditor on 127.0.0.1:$PEQEDITOR_PORT"

  mv /var/www/peqphpeditor/config.php.dist /var/www/peqphpeditor/config.php
  sed -i -e "s/\$dbhost = 'localhost';/\$dbhost = '$EQ_MYSQL_DB_HOST';/gI" /var/www/peqphpeditor/config.php
  sed -i -e "s/\$dbuser = 'username';/\$dbuser = '$EQ_MYSQL_USER';/gI" /var/www/peqphpeditor/config.php
  sed -i -e "s/\$dbpass = 'password';/\$dbpass = '$EQ_MYSQL_PASSWORD';/gI" /var/www/peqphpeditor/config.php
  sed -i -e "s/\$db = 'database_name';/\$db = '$EQ_MYSQL_DATABASE';/gI" /var/www/peqphpeditor/config.php
  # Set default login, prob want to disable this if not running on localhost
  sed -i -e "s/\$login = '';/\$login = 'admin';/gI" /var/www/peqphpeditor/config.php
  sed -i -e "s/\$password = '';/\$password = 'password';/gI" /var/www/peqphpeditor/config.php

  sed -i -r "s/Listen 80/Listen $PEQEDITOR_PORT/gI" /etc/apache2/ports.conf
  echo "<VirtualHost *:$PEQEDITOR_PORT>
  	ServerAdmin webmaster@localhost
  	DocumentRoot /var/www/peqphpeditor
  	ServerName peqeditor.com
    ServerAlias www.peqeditor.com
  	ErrorLog ${APACHE_LOG_DIR}/error.log
  	CustomLog ${APACHE_LOG_DIR}/access.log combined
  </VirtualHost>
  " > /etc/apache2/sites-available/peqeditor.com.conf
  a2ensite peqeditor.com.conf
  service apache2 start
  service apache2 reload
fi

# Create shared memory
echo "Creating shared memory cache"
cd /root/server
mkdir /root/server/shared
/root/server/shared_memory

echo "Done initializing! Running server..."

# Start supervisor
/usr/bin/supervisord -n
