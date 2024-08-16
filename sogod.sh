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

    # Determine which database to use: MySQL or PostgreSQL
    if [ -n "$MYSQL_HOST" ] && [ -n "$POSTGRESQL_HOST" ]; then
        echo "Error: Both MySQL and PostgreSQL configurations are defined. Please choose one."
        exit 1
    elif [ -n "$MYSQL_HOST" ];then
        db_type="mysql"
        db_host="${MYSQL_HOST}"
        db_port="${MYSQL_PORT:-3306}"
        db_user="${MYSQL_USER:-sogo}"
        db_password="${MYSQL_PASSWORD:-sogoPassword}"
        db_name="${MYSQL_DATABASE:-sogo}"
        db_url="mysql://${db_user}:${db_password}@${db_host}:${db_port}/${db_name}"
    elif [ -n "$POSTGRESQL_HOST" ]; then
        db_type="postgresql"
        db_host="${POSTGRESQL_HOST}"
        db_port="${POSTGRESQL_PORT:-5432}"
        db_user="${POSTGRESQL_USER:-sogo}"
        db_password="${POSTGRESQL_PASSWORD:-sogoPassword}"
        db_name="${POSTGRESQL_DATABASE:-sogo}"
        db_url="postgresql://${db_user}:${db_password}@${db_host}:${db_port}/${db_name}"
    else
        db_type="none"
        echo "No MySQL or PostgreSQL configuration defined. The initial database configuration will remain unchanged."
    fi

    # Apply environment variables if they are defined
    awk -v imap="${MAIL_IMAP_SERVER:-127.0.0.1}" \
        -v smtp="${MAIL_SMTP_SERVER:-127.0.0.1}" \
        -v sieve="${MAIL_SIEVE_SERVER:-sieve://127.0.0.1:4190}" \
        -v mail_domain="${MAIL_DOMAIN:-example.com}" \
        -v drafts_folder="${MAIL_DRAFTS_FOLDER_NAME:-Drafts}" \
        -v sent_folder="${MAIL_SENT_FOLDER_NAME:-Sent}" \
        -v trash_folder="${MAIL_TRASH_FOLDER_NAME:-Trash}" \
        -v sieve_enabled="${MAIL_SIEVE_SCRIPTS_ENABLED:-YES}" \
        -v vacation_enabled="${MAIL_VACATION_ENABLED:-YES}" \
        -v forward_enabled="${MAIL_FORWARD_ENABLED:-YES}" \
        -v sieve_encoding="${MAIL_SIEVE_FOLDER_ENCODING:-UTF-8}" \
        -v password_change="${MAIL_PASSWORD_CHANGE_ENABLED:-NO}" \
        -v spool_path="${MAIL_SPOOL_PATH:-/var/spool/sogo}" \
        -v mail_check="${MAIL_MESSAGE_CHECK:-manually}" \
        -v appointment_notifications="${MAIL_APPOINTMENT_SEND_EMAIL_NOTIFICATIONS:-YES}" \
        -v enable_alarms="${MAIL_ENABLE_EMAIL_ALARMS:-YES}" \
        -v sogo_language="${SOGO_LANGUAGE:-French}" \
        -v sogo_timezone="${SOGO_TIMEZONE:-Europe/Paris}" \
        -v sogo_page_title="${SOGO_PAGE_TITLE:-My SOGo Server}" \
        -v sogo_login_title="${SOGO_LOGIN_TITLE:-Welcome to SOGo}" \
        -v debug_requests="${SOGO_DEBUG_REQUESTS:-YES}" \
        -v debug_base_url="${SOGO_DEBUG_BASE_URL:-YES}" \
        -v refresh_view_check="${SOGO_REFRESH_VIEW_CHECK:-every_5_minutes}" \
        -v refresh_on_foreground="${SOGO_REFRESH_VIEW_ON_FOREGROUND:-YES}" \
        -v reply_placement="${SOGO_MAIL_REPLY_PLACEMENT:-below}" \
        -v signature_placement="${SOGO_MAIL_SIGNATURE_PLACEMENT:-below}" \
        -v forwarding_method="${SOGO_MAIL_MESSAGE_FORWARDING:-inline}" \
        -v logging_level="${SOGO_LOGGING_LEVEL:-debug}" \
        -v db_type="${db_type}" \
        -v db_url="${db_url}" \
        '{
            gsub(/SOGoIMAPServer = "127.0.0.1";/, "SOGoIMAPServer = \"" imap "\";");
            gsub(/SOGoSMTPServer = "127.0.0.1";/, "SOGoSMTPServer = \"" smtp "\";");
            gsub(/SOGoSieveServer = "sieve:\/\/127.0.0.1:4190";/, "SOGoSieveServer = \"" sieve "\";");
            gsub(/SOGoMailDomain = "example.com";/, "SOGoMailDomain = \"" mail_domain "\";");
            gsub(/SOGoDraftsFolderName = Drafts;/, "SOGoDraftsFolderName = \"" drafts_folder "\";");
            gsub(/SOGoSentFolderName = Sent;/, "SOGoSentFolderName = \"" sent_folder "\";");
            gsub(/SOGoTrashFolderName = Trash;/, "SOGoTrashFolderName = \"" trash_folder "\";");
            gsub(/SOGoSieveScriptsEnabled = YES;/, "SOGoSieveScriptsEnabled = " sieve_enabled ";");
            gsub(/SOGoVacationEnabled = YES;/, "SOGoVacationEnabled = " vacation_enabled ";");
            gsub(/SOGoForwardEnabled = YES;/, "SOGoForwardEnabled = " forward_enabled ";");
            gsub(/SOGoSieveFolderEncoding = UTF-8;/, "SOGoSieveFolderEncoding = \"" sieve_encoding "\";");
            gsub(/SOGoPasswordChangeEnabled = NO;/, "SOGoPasswordChangeEnabled = " password_change ";");
            gsub(/SOGoMailSpoolPath = "\/var\/spool\/sogo";/, "SOGoMailSpoolPath = \"" spool_path "\";");
            gsub(/SOGoMailMessageCheck = manually;/, "SOGoMailMessageCheck = " mail_check ";");
            gsub(/SOGoAppointmentSendEMailNotifications = YES;/, "SOGoAppointmentSendEMailNotifications = " appointment_notifications ";");
            gsub(/SOGoEnableEMailAlarms = YES;/, "SOGoEnableEMailAlarms = " enable_alarms ";");
            gsub(/SOGoLanguage = French;/, "SOGoLanguage = \"" sogo_language "\";");
            gsub(/SOGoTimeZone = Europe\/Paris;/, "SOGoTimeZone = \"" sogo_timezone "\";");
            gsub(/SOGoPageTitle = "My SOGo Server";/, "SOGoPageTitle = \"" sogo_page_title "\";");
            gsub(/SOGoLoginTitle = "Welcome to SOGo";/, "SOGoLoginTitle = \"" sogo_login_title "\";");
            gsub(/SOGoDebugRequests = YES;/, "SOGoDebugRequests = \"" debug_requests "\";");
            gsub(/SOGoDebugBaseURL = YES;/, "SOGoDebugBaseURL = \"" debug_base_url "\";");
            gsub(/SOGoRefreshViewCheck = every_5_minutes;/, "SOGoRefreshViewCheck = " refresh_view_check ";");
            gsub(/SOGoRefreshViewOnForeground = YES;/, "SOGoRefreshViewOnForeground = " refresh_on_foreground ";");
            gsub(/SOGoMailReplyPlacement = below;/, "SOGoMailReplyPlacement = " reply_placement ";");
            gsub(/SOGoMailSignaturePlacement = below;/, "SOGoMailSignaturePlacement = " signature_placement ";");
            gsub(/SOGoMailMessageForwarding = inline;/, "SOGoMailMessageForwarding = " forwarding_method ";");
            gsub(/SOGoLoggingLevel = debug;/, "SOGoLoggingLevel = \"" logging_level "\";");

            # Replace MySQL or PostgreSQL URLs only if a database type is specified
            if (db_type != "none") {
                gsub(/mysql:\/\/sogo:sogoPassword@host.docker.internal:3306\/sogo/, db_url);
            }

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
    exec gosu sogo /usr/sbin/sogod -WONoDetach YES
fi