#!/bin/bash

# Start Apache
service apache2 start

# Start SOGo
service sogo start

# Start Memcached
service memcached start

# Keep the container running
tail -f /dev/null