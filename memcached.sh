#!/bin/sh
exec gosu memcache /usr/bin/memcached -m ${memcached:-64}