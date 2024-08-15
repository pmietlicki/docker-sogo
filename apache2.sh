#!/bin/sh

# Create a directory in /srv to store configuration backups
mkdir -p /srv/etc

# If the SOGo Apache configuration doesn't exist, download it
if [ ! -f /etc/apache2/conf-available/SOGo.conf ]; then
    curl -s https://raw.githubusercontent.com/inverse-inc/sogo/master/Apache/SOGo.conf -o /etc/apache2/conf-available/SOGo.conf
fi

# Back up the original SOGo configuration
cp /etc/apache2/conf-available/SOGo.conf /srv/etc/apache-SOGo.conf.orig

# Copy the administrator's version back to the Apache configuration
cp /srv/etc/apache-SOGo.conf /etc/apache2/conf-enabled/SOGo.conf

# Run Apache in the foreground with no detachment
APACHE_ARGUMENTS="-DNO_DETACH" exec /usr/sbin/apache2ctl start
