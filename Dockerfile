FROM ubuntu

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris

# Install Apache, SOGo, and other dependencies
RUN apt-get update && \
    apt-get -o Dpkg::Options::="--force-confold" upgrade -q -y --force-yes && \
    apt-get install -y --no-install-recommends gettext-base apache2 sogo memcached libssl-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Activate required Apache modules
RUN a2enmod headers proxy proxy_http rewrite ssl

# Move SOGo's data directory to /srv
RUN usermod --home /srv/lib/sogo sogo

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libssl.so
ENV USEWATCHDOG=YES

# Configuration scripts for Apache, SOGo, and Memcached
ADD start.sh /start.sh
RUN chmod +x /start.sh

# Interface the environment
VOLUME /srv
EXPOSE 80 443 8800

# Start script
ENTRYPOINT ["/start.sh"]