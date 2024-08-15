#!/bin/sh

# Create a directory in /srv to store configuration backups
mkdir -p /srv/etc

# If the SOGo Apache configuration doesn't exist, download it
if [ ! -f /etc/apache2/conf-available/SOGo.conf ]; then
    curl -s https://raw.githubusercontent.com/inverse-inc/sogo/master/Apache/SOGo.conf -o /etc/apache2/conf-available/SOGo.conf
fi
cp /etc/apache2/conf-available/SOGo.conf /srv/etc/apache-SOGo.conf.orig

# Check if custom config exists and copy, else enable default config
if [ -f /srv/etc/apache-SOGo.conf ]; then
	cp /srv/etc/apache-SOGo.conf /etc/apache2/conf-enabled/SOGo.conf
else
	a2enconf SOGo.conf
fi

# Run apache in foreground
exec /usr/sbin/apache2ctl -D FOREGROUND