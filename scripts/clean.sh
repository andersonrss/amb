#!/bin/bash

# Testing if we have the instance parameter
if [ -z "$1" ]; then
    echo "Not given an instance name. Exiing..."
    exit
fi

INSTANCE=$1

# Changing to the script directory
cd "${0%/*}"

userdel ${INSTANCE}
rm -rf /home/${INSTANCE}
#sudo -u postgres psql -U postgres -c "drop database ${INSTANCE}"
#sudo -u postgres dropuser ${INSTANCE}

rm /etc/supervisor/conf.d/${INSTANCE}.conf
supervisorctl reread
supervisorctl update

rm /etc/nginx/sites-available/${INSTANCE}
rm /etc/nginx/sites-enabled/${INSTANCE}
service nginx restart

rm -rf ../installed_instances/${INSTANCE}

