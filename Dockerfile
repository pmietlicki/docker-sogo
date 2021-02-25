FROM phusion/baseimage:master

# Add sources for sogo latest (v5)
RUN echo "deb [trusted=yes] http://www.axis.cz/linux/debian $(lsb_release -sc) sogo-v5" > /etc/apt/sources.list.d/sogo.list

# Fix install problem with this repo
RUN mkdir -p /usr/share/doc/sogo
RUN touch /usr/share/doc/sogo/empty.sh

# Install Apache, SOGo from repository
RUN apt-get update && \
    apt-get -o Dpkg::Options::="--force-confold" upgrade -q -y --force-yes && \
    apt-get install -y --no-install-recommends gettext-base apache2 sogo sogo-activesync memcached libssl-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Activate required Apache modules
RUN a2enmod headers proxy proxy_http rewrite ssl

# Move SOGo's data directory to /srv
RUN usermod --home /srv/lib/sogo sogo

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libssl.so
ENV USEWATCHDOG=YES

# SOGo daemons
RUN mkdir /etc/service/sogod /etc/service/apache2 /etc/service/memcached
ADD sogod.sh /etc/service/sogod/run
ADD apache2.sh /etc/service/apache2/run
ADD memcached.sh /etc/service/memcached/run

# Make GATEWAY host available, control memcached startup
RUN mkdir -p /etc/my_init.d
ADD memcached-control.sh /etc/my_init.d/

# Interface the environment
VOLUME /srv
EXPOSE 80 443 8800

# Baseimage init process
ENTRYPOINT ["/sbin/my_init"]