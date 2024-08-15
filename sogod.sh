#!/bin/sh

# Create and set permissions for the SOGo runtime directory
mkdir -p /var/run/sogo
touch /var/run/sogo/sogo.pid
chown -R sogo:sogo /var/run/sogo

# Set the LD_LIBRARY_PATH for SOGo
echo "LD_LIBRARY_PATH=/usr/lib/sogo:/usr/lib:$LD_LIBRARY_PATH" >> /etc/default/sogo

# Solve the libssl issue for Mail View
if [ -z "${LD_PRELOAD}" ]; then
    LIBSSL_LOCATION=$(find / -type f -name "libssl.so.*" -print -quit)
    echo "LD_PRELOAD=$LIBSSL_LOCATION" >> /etc/default/sogo
    export LD_PRELOAD=$LIBSSL_LOCATION
else
    echo "LD_PRELOAD=$LD_PRELOAD" >> /etc/default/sogo
    export LD_PRELOAD=$LD_PRELOAD
fi

# Backup and restore SOGo configuration
mkdir -p /srv/etc
cp /etc/sogo/sogo.conf /srv/etc/sogo.conf.orig
cp /srv/etc/sogo.conf /etc/sogo/sogo.conf

# Ensure SOGo home directory exists and set ownership
mkdir -p /srv/lib/sogo
chown -R sogo /srv/lib/sogo

# Backup and restore the SOGo crontab
cp /etc/cron.d/sogo /srv/etc/cron.orig
cp /srv/etc/cron /etc/cron.d/sogo

# Run SOGo in the foreground with setuser
exec /sbin/setuser sogo /usr/sbin/sogod -WOUseWatchDog $USEWATCHDOG -WONoDetach YES -WOPort 20000 -WOPidFile /var/run/sogo/sogo.pid
