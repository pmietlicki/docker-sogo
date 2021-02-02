#!/bin/sh
if [ $FOREGROUND="NO" ] then
	exec /etc/init.d/memcached start
else
	exec /sbin/setuser memcache /usr/bin/memcached -m ${memcached:-64} >>/var/log/memcached.log 2>&1
fi
