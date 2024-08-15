#!/bin/sh

# Vérifie si la variable memcached est définie à "false"
if [ "$memcached" = "false" ]; then
  echo "Memcached is disabled."
else
  # Définit la valeur par défaut à 64 MiB si aucune valeur n'est spécifiée
  exec gosu memcache /usr/bin/memcached -m ${memcached:-64}
fi