#!/bin/bash

# Initialize directories and permissions
mkdir -p /var/run/sogo /srv/etc /srv/lib/sogo /etc/sogo
touch /var/run/sogo/sogo.pid
chown -R sogo:sogo /var/run/sogo /srv/lib/sogo

# Paths to configuration files
CONFIG_PATH="/srv/etc/sogo.conf"
DEFAULT_CONFIG="/etc/sogo/sogo.conf.default"

# Check if a personalized configuration exists
if [ ! -f "$CONFIG_PATH" ]; then
    echo "No personalized SOGo configuration found. Creating a default configuration."

    # Copy the default config to the working config path
    cp "$DEFAULT_CONFIG" "$CONFIG_PATH"

    # Apply environment variables if they are defined
    awk -v imap="$SOGoIMAPServer" -v smtp="$SOGoSMTPServer" -v mysql_host="$MYSQL_HOST" -v mysql_password="$MYSQL_PASSWORD" -v pg_host="$POSTGRESQL_HOST" -v pg_password="$POSTGRESQL_PASSWORD" '
    {
        if ($1 == "SOGoIMAPServer") $3 = "\""imap"\";";
        if ($1 == "SOGoSMTPServer") $3 = "\""smtp"\";";
        gsub(/host.docker.internal/, mysql_host);
        gsub(/sogoPassword/, mysql_password);
        gsub(/host.docker.internal/, pg_host);
        gsub(/sogoPassword/, pg_password);
        print;
    }' "$CONFIG_PATH" > "$CONFIG_PATH.tmp" && mv "$CONFIG_PATH.tmp" "$CONFIG_PATH"

    # Save the original for reference
    cp "$CONFIG_PATH" /srv/etc/sogo.conf.orig
else
    echo "Using existing personalized SOGo configuration."
fi

# Ensure that the configuration is applied
cp "$CONFIG_PATH" /etc/sogo/sogo.conf

# Verify that the configuration file is correctly formatted
if ! grep -q "{" /etc/sogo/sogo.conf || ! grep -q "}" /etc/sogo/sogo.conf; then
    echo "Error: sogo.conf is not properly formatted."
    exit 1
fi

# Solve libssl bug for Mail View
if [[ -z "${LD_PRELOAD}" ]]; then
    LIBSSL_LOCATION=$(find / -type f -name "libssl.so.*" -print -quit)
    echo "LD_PRELOAD=$LIBSSL_LOCATION" >> /etc/default/sogo
    echo "LD_LIBRARY_PATH=/usr/local/lib/sogo:/usr/local/lib:$LD_LIBRARY_PATH" >> /etc/default/sogo
    export LD_PRELOAD=$LIBSSL_LOCATION
else
    echo "LD_PRELOAD=$LD_PRELOAD" >> /etc/default/sogo
    echo "LD_LIBRARY_PATH=/usr/local/lib/sogo:/usr/local/lib:$LD_LIBRARY_PATH" >> /etc/default/sogo
    export LD_PRELOAD=$LD_PRELOAD
fi

# Copy the original crontab file for reference
cp /etc/cron.d/sogo /srv/etc/cron.orig

# Load custom crontab if it exists
if [ -f "/srv/etc/cron" ]; then
    cp /srv/etc/cron /etc/cron.d/sogo
    printf "\n" >> /etc/cron.d/sogo
else
    echo "No custom cron file found at /srv/etc/cron. Skipping cron setup."
fi

# Load the GNUstep environment
. /usr/share/GNUstep/Makefiles/GNUstep.sh

# Run SOGo in the foreground
if pgrep -x "sogod" > /dev/null; then
    echo "SOGo is already running"
else
    exec gosu sogo /usr/local/sbin/sogod -WONoDetach YES
fi