# SOGo for Docker

[SOGo](http://www.sogo.nu) is fully supported and trusted groupware server with a focus on scalability and open standards. SOGo is released under the GNU GPL/LGPL v2 and above. 

This Dockerfile packages SOGo as packaged by ubuntu, together with Apache 2 and memcached.

## Setup

The image stores configuration, logs and backups in `/srv`, which you should persist somewhere. Example configuration is copied during each startup of the container, which you can adjust for your own use. For creating the initial directory hierarchy and example configuration, simply run the container with the `/srv` volume already exposed or linked, for example using

    docker run -v /srv/sogo:/srv pmietlicki/sogo

As soon as the files are created, stop the image again. You will now find following files:

    .
    ├── etc
    │   ├── apache-SOGo.conf.orig
    │   └── sogo.conf.orig
    └── lib
        └── sogo
            └── GNUstep
                ├── Defaults
                └── Library

Create copies of the configuration files named `apache-SOGo.conf` and `sogo.conf.orig`. Don't change or link the `.orig` files, as they will be overwritten each time the container is started. They can also be used to see differences on your configuration after SOGo upgrades.

### Database

A separate database is required, for example a PostgreSQL container as provided by the Docker image [`postgres`](https://hub.docker.com/_/postgres), but also any other database management system SOGo supports can be used. Follow the _Database Configuration_ chapter of the SOGo documentation on these steps, and modify the sogo.conf` file accordingly. The following documentation will expect the database to be available with the SOGo default credentials given by the official documentation, adjust them as needed. If you link a database container, remember that it will be automatically added to the hosts file and be available under the chosen name.

For a container named `sogo-postgresql` linked as `db` using `--link="sogo-postgresql:db"` with default credentials, you would use following lines in the `sogo.conf`:

    SOGoProfileURL = "postgresql://sogo:sogo@db:5432/sogo/sogo_user_profile";
    OCSFolderInfoURL = "postgresql://sogo:sogo@db:5432/sogo/sogo_folder_info";
    OCSSessionsFolderURL = "postgresql://sogo:sogo@db:5432/sogo/sogo_sessions_folder";

SOGo performs schema initialziation lazily on startup, thus no database initialization scripts must be run.

### memcached

As most users will not want to separate memcached, there is a built-in daemon. It can be controled by setting the environment variable `memcached`. If set to `false`, the built-in memcached will not start, make sure to configure an external one. Otherwise, the variable holds the amount of memory dedicated to memcached in MiB. If unset, a default of 64MiB will be used.

### Sending Mail

    SOGoMailingMechanism = "smtp";
    SOGoSMTPServer = "yoursmtpserver.localdomain.local";
 
For further details in MTA configuration including SMTP auth, refer to SOGo's documentation.

### Apache and HTTPs

As already given above, the default Apache configuration is already available under `etc/apache-SOGo.conf.orig`. The container exposes HTTP (80), HTTPS (443) and 8800, which is used by Apple devices, and 20000, the default port the SOGo daemon listens on. You can either directly include the certificates within the container, or use an external proxy for this. Make sure to only map the required ports to not unnecessarily expose daemons.

You need to adjust the `<Proxy ...>` section and include port, server name and url to match your setup.

    <Proxy http://127.0.0.1:20000/SOGo>
    ## adjust the following to your configuration
      RequestHeader set "x-webobjects-server-port" "80"
      RequestHeader set "x-webobjects-server-name" "%{HTTP_HOST}e" env=HTTP_HOST
      RequestHeader set "x-webobjects-server-url" "http://%{HTTP_HOST}e" env=HTTP_HOST

If you want to support iOS-devices, add appropriate `.well-known`-rewrites in either the Apache configuration or an external proxy.

For ActiveSync support, additionally add/uncomment the following lines:

    ProxyPass /Microsoft-Server-ActiveSync \
      http://127.0.0.1:20000/SOGo/Microsoft-Server-ActiveSync \
      retry=60 connectiontimeout=5 timeout=360


### Cron-Jobs: Backup, Session Timeout, Sieve

SOGo heavily relies on cron jobs for different purposes. The image provides SOGo's original cron file as `./etc/cron.orig`. Copy and edit it as `./etc/cron`. The backup script is available and made executable at the predefined location `/usr/share/doc/sogo/sogo-backup.sh`, so backup is fully functional immediately after uncommenting the respective cron job.

### Further Configuration

Unlike the Debian and probably other SOGo packages, the number of worker processes is not set in `/etc/default/sogo`, but the normal `sogo.conf`. Remember to start a reasonable number of worker processes matching to your needs (8 will not be enough for medium and larger instances):

    WOWorkersCount = 8;

ActiveSync requires one worker per concurrent connection.

All other configuration options have no special considerations.

## Running a Container

Run the image in a container, expose ports as needed and making `/srv` permanent. An example run command, which links to a database container named `db` and uses an external HTTP proxy for wrapping in HTTPS might be

    docker run -d \
      --name='sogo' \
      --publish='127.0.0.1:80:80' \
      --link='sogo-postgresql:db' \
      --volume='/srv/sogo:/srv' \
      pmietlicki/sogo

## Upgrading and Maintenance

Most of the time, no special action must be performed for upgrading SOGo. Read the _Upgrading_ section of the [Installation Manual](http://www.sogo.nu/files/docs/SOGo%20Installation%20Guide.pdf) prior upgrading the container to verify whether anything special needs to be considered.

As the image builds on [`phusion/baseimage`](https://github.com/phusion/baseimage-docker), you can get a shell for running update scripts when necessary or perform similar maintenance operations by adding `/sbin/my_init -- /bin/bash` as run command and subsequently attaching to the container:

    docker run -t -i -d \
      --name='sogo' \
      --publish='127.0.0.1:80:80' \
      --link='sogo-postgresql:db' \
      --volume='/srv/sogo:/srv' \
      pmietlicki/sogo /sbin/my_init -- /bin/bash

This is fine for running update scripts on the database. To be able to perform persistent changes to the file system (without creating new containers), red the [`phusion/baseimage`](https://github.com/phusion/baseimage-docker) documentation on attaching to the container.

## Rancher usage example

I created a stolon external database under stolon-proxy.pg12, then created a new user and database named "sogo" under pgadmin4.

### Variables
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libssl.so
You can also set http_proxy, https_proxy and no_proxy if you are behind a corporate proxy for example.

### Health and liveness check 
For Health Check, you can check "HTTP request returns a successful status (2xx or 3xx)" with a request path to "/SOGo" on port 80

### Volumes
I put all the configuration with Config Map named sogo and Config Map values (sogo.conf and apache-SOGo.conf, optionnaly sogo for cron.d, **it is case sensitive**).
Then for the volumes, I used :
* Volume Name : sogo-conf
* Default Mode : 644
* Config Map Name : sogo with Items : All keys
* Mount Point : /srv/etc/

* Volume Name : sogo-nfs
* Persisent Volume Claim : sogo-nfs (a new persistent volume claim with nfs as default provider with Many Nodes Read-Write)
* Mount Point : /srv

#### cron (if needed)
* Volume Name : cron-sogo
* Default Mode : 644
* Config Map Name : sogo with Items : Select Specific Keys
* Key : sogo
* Path : sogo
* Mode : 644
* Mount Point : /srv/etc/cron

### Configuration exemple

#### apache-SOGo.conf

    Alias /SOGo.woa/WebServerResources/ \
      /usr/lib/GNUstep/SOGo/WebServerResources/
    Alias /SOGo/WebServerResources/ \
      /usr/lib/GNUstep/SOGo/WebServerResources/
    <Directory /usr/lib/GNUstep/SOGo/>
       AllowOverride None
      <IfVersion < 2.4>
          Order deny,allow
          Allow from all
      </IfVersion>
      <IfVersion >= 2.4>
          Require all granted
      </IfVersion>
      <IfModule expires_module>
        ExpiresActive On
        ExpiresDefault "access plus 1 year"
      </IfModule>
    </Directory>
    ProxyRequests Off
    SetEnv proxy-nokeepalive 1
    ProxyPreserveHost On
    #Example for redirect from / to /SOGo
    RedirectMatch ^/$ http://webmail.localdomain.local/SOGo
    ProxyPass /SOGo http://127.0.0.1:20000/SOGo retry=0
    <Proxy http://127.0.0.1:20000/SOGo>
      <IfModule headers_module>
        RequestHeader set "x-webobjects-server-port" "80"
        RequestHeader set "x-webobjects-server-name" "%{HTTP_HOST}e" env=HTTP_HOST
        RequestHeader set "x-webobjects-server-url" "http://%{HTTP_HOST}e" env=HTTP_HOST
        ## When using proxy-side autentication, you need to uncomment and
        ## adjust the following line:
        RequestHeader unset "x-webobjects-remote-user"
        #RequestHeader set "x-webobjects-remote-user" "%{REMOTE_USER}e" env=REMOTE_USER
        RequestHeader set "x-webobjects-server-protocol" "HTTP/1.0"
      </IfModule>
    AddDefaultCharset UTF-8
    Order allow,deny
    Allow from all
    </Proxy>
    #For Apple autoconfiguration
    <IfModule rewrite_module>
      RewriteEngine On
      RewriteRule ^/.well-known/caldav/?$ /SOGo/dav [R=301]
      RewriteRule ^/.well-known/carddav/?$ /SOGo/dav [R=301]
    </IfModule>

#### sogo.conf
    {
        SOGoProfileURL = "postgresql://sogo:sogo@stolon-proxy.pg12:5432/sogo/sogo_user_profile";
        OCSFolderInfoURL = "postgresql://sogo:sogo@stolon-proxy.pg12:5432/sogo/sogo_folder_info";
        OCSSessionsFolderURL = "postgresql://sogo:sogo@stolon-proxy.pg12:5432/sogo/sogo_sessions_folder";
        OCSEMailAlarmsFolderURL = "postgresql://sogo:sogo@stolon-proxy.pg12:5432/sogo/sogo_alarms_folder";
        SOGoLanguage = English;
        SOGoPageTitle = "Webmail";
        SOGoAppointmentSendEMailNotifications = YES;
        SOGoMailingMechanism = smtp;
        SOGoSMTPServer = smtp-server.localdomain.local;
        SOGoTimeZone = UTC;
        SOGoSentFolderName = Sent;
        SOGoTrashFolderName = Trash;
        SOGoDraftsFolderName = Drafts;
        SOGoIMAPServer = "imaps://imap-server.localdomain.local:143/?tls=YES";
        SOGoIMAPAclConformsToIMAPExt = YES;
        SOGoVacationEnabled = NO;
        SOGoForwardEnabled = NO;
        SOGoSieveScriptsEnabled = NO;
        SOGoFirstDayOfWeek = 0;
        SOGoMailMessageCheck = manually;
        SOGoMailAuxiliaryUserAccountsEnabled = NO;
        SOGoMemcachedHost = 127.0.0.1;
        WOWorkersCount = 8;
        /* LDAP authentication example */
        SOGoUserSources = (
        {
           type = ldap;
           CNFieldName = cn;
           UIDFieldName = uid;
           IDFieldName = uid; // first field of the DN for direct binds
           bindFields = (mail, uid); // array of fields to use for indirect binds
           baseDN = "ou=mycompany,o=localdomain,c=local";
           bindDN = "cn=Directory Manager";
           bindPassword = "mypassword";
           canAuthenticate = YES;
           displayName = "Company Address Book";
           hostname = ldap://ldap.localdomain.local:389;
           id = public;
           isAddressBook = YES;
        }
        );
    }

#### cron.d/sogo (if needed)
    # Sogod cronjobs
    # Vacation messages expiration
    # The credentials file should contain the sieve admin credentials (username:passwd)
    #0 0 * * *      sogo    /usr/sbin/sogo-tool update-autoreply -p /etc/sogo/sieve.creds
    # Session cleanup - runs every minute
    #   - Ajust the nbMinutes parameter to suit your needs
    # Example: Sessions without activity since 60 minutes will be dropped:
    #* * * * *      sogo    /usr/sbin/sogo-tool expire-sessions 60 > /dev/null 2>&1
    # Email alarms - runs every minutes
    # If you need to use SMTP AUTH for outgoing mails, specify credentials to use
    # with '-p /path/to/credentialsFile' (same format as the sieve credentials)
    #* * * * *      sogo    /usr/sbin/sogo-ealarms-notify > /dev/null 2>&1
    # Daily backups
    #   - writes backups to /var/backups/sogo/
    #   - will keep 31 days worth of backups by default
    #   - runs once a day by default, but can run more frequently
    #30 0 * * *     sogo   /usr/sbin/sogo-backup