FROM ubuntu

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris

# Install basic dependencies including lsb-release, curl, jq, and gpg
RUN apt-get update && \
    apt-get install -y --no-install-recommends lsb-release wget gosu apt-transport-https gnupg2 curl jq gettext-base apache2 memcached libssl-dev supervisor ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Fetch the latest SOGo version dynamically and configure the repository
RUN LATEST_VERSION=$(curl -s https://api.github.com/repos/Alinto/sogo/releases/latest | jq -r '.tag_name' | awk -F '[.-]' '{print $2}') && \
    DISTRO=$(lsb_release -c -s) && \
    echo "deb http://packages.sogo.nu/nightly/${LATEST_VERSION}/ubuntu/ $DISTRO $DISTRO" > /etc/apt/sources.list.d/sogo.list && \
    wget -qO- https://keys.openpgp.org/vks/v1/by-fingerprint/74FFC6D72B925A34B5D356BDF8A27B36A6E2EAE9 | gpg --dearmor -o /usr/share/keyrings/sogo-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/sogo-archive-keyring.gpg] http://packages.sogo.nu/nightly/${LATEST_VERSION}/ubuntu/ $DISTRO $DISTRO" >> /etc/apt/sources.list.d/sogo.list && \
    apt-get update && apt-get install -y sogo

# Activate required Apache modules
RUN a2enmod headers proxy proxy_http rewrite ssl

# Move SOGo's data directory to /srv
RUN usermod --home /srv/lib/sogo sogo

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libssl.so
ENV USEWATCHDOG=YES

# Copy supervisord configuration and service startup scripts
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY apache2.sh /etc/init.d/apache2.sh
COPY sogod.sh /etc/init.d/sogod.sh
COPY memcached.sh /etc/init.d/memcached.sh

# Make the service startup scripts executable
RUN chmod +x /etc/init.d/apache2.sh /etc/init.d/sogod.sh /etc/init.d/memcached.sh

# Interface the environment
VOLUME /srv
EXPOSE 80 443 8800

# Start Supervisord to manage all services
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
