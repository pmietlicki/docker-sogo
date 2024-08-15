#!/bin/sh
exec /sbin/setuser memcache /usr/bin/memcached -m ${memcached:-64} 
