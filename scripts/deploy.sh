#!/bin/bash

echo "PNG-Coorporation Freyja Deploy Script v1.0a"

# Verify if you are root ..
if [ "$(id -u)" != "0" ]; then
   echo "*** This script must be run as root... exiting" 1>&2
   exit 1
fi

# Changing to the script directory
cd "${0%/*}"

# Starting the things ...
echo "Phase 1: Instance Informations"
echo "... What is the instance name (ex.: pilates22): "
read instance_name
echo "[OK]"

echo "Phase 2: Generating passwords"
PASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9-_!@#$%^&_+<>?=' | fold -w 30 | grep -i '[!@#$%^&_+<>?=]' | head -n 1`
DJANGO_SKEY=`cat /dev/urandom | tr -dc 'a-zA-Z0-9-_!@#$%^&_+<>?=' | fold -w 50 | grep -i '[!@#$%^&_+<>?=]' | head -n 1`
echo "[OK]"

echo "Phase 3: Creating System User"
adduser --quiet --disabled-password --shell /bin/bash --home /home/${instance_name} --gecos "Freyja User" ${instance_name}
echo "${instance_name}:${PASSWORD}" | chpasswd
echo "[OK]"

echo "Phase 4: Downloading Freyja from Bitbucket"
sudo -u ${instance_name} git clone https://nailsoncunha@github.com/nailsoncunha/danda_mestre.git /home/${instance_name}/freyja
echo "[OK]"

echo "Phase 5: Preparing the VirtualEnv"
sudo -u ${instance_name} mkdir /home/${instance_name}/venv
sudo -u ${instance_name} virtualenv /home/${instance_name}/venv
#sudo -u ${instance_name} python3 -m venv /home/${instance_name}/venv
source /home/${instance_name}/venv/bin/activate
pip install -r ../pip_packages.txt
deactivate
echo "[OK]"

echo "Phase 6: Preparing the Database"
#sudo -u postgres createuser ${instance_name}
#sudo -u postgres createdb --owner ${instance_name} ${instance_name}
#echo postgres psql postgres -c "ALTER USER ${instance_name} WITH ENCRYPTED PASSWORD '${PASSWORD}'"
#sudo -u postgres psql postgres -c "ALTER USER ${instance_name} WITH ENCRYPTED PASSWORD '${PASSWORD}'"
echo "[OK]"

echo "Phase 7: local_settings"
#local_settings="/home/${instance_name}/freyja/pilates/local_settings.py"
#touch ${local_settings}
#chown ${instance_name}.${instance_name} ${local_settings}
#echo "def update_settings( global_settings_vars ):" >> ${local_settings}
#echo "    global_settings_vars[ 'SECRET_KEY' ] = '${DJANGO_SKEY}'" >> ${local_settings}
#echo "    global_settings_vars[ 'ALLOWED_HOSTS' ] += [ u'${instance_name}.pngweb.com.br', u'www.${instance_name}.pngweb.com.br' ]" >> ${local_settings}
#echo "    global_settings_vars[ 'DATABASES' ][ 'default' ] = { 'ENGINE': 'django.db.backends.postgresql'," >> ${local_settings}
#echo "                                                         'NAME': '${instance_name}'," >> ${local_settings}
#echo "                                                         'USER': '${instance_name}'," >> ${local_settings}
#echo "                                                         'PASSWORD': '${PASSWORD}'," >> ${local_settings}
#echo "                                                         'HOST': '127.0.0.1',"  >> ${local_settings}
#echo "                                                         'PORT': '5432'," >> ${local_settings}
#echo "                                                       }" >> ${local_settings}
echo "[OK]"

echo "Phase 8: Migration"
#sudo -u ${instance_name} ./envrun.sh ${instance_name} /home/${instance_name}/freyja/manage.py createdb
sudo -u ${instance_name} ./envrun.sh ${instance_name} /home/${instance_name}/freyja/manage.py makemigrations
sudo -u ${instance_name} ./envrun.sh ${instance_name} /home/${instance_name}/freyja/manage.py migrate
#sudo -u ${instance_name} ./envrun.sh ${instance_name} /home/${instance_name}/freyja/manage.py setup
echo "[OK]"


echo "Phase 9: Preparing Basic Folders"
echo "   logs"
sudo -u ${instance_name} mkdir /home/${instance_name}/logs

echo "   gunicorn"
sudo -u ${instance_name} mkdir /home/${instance_name}/gunicorn

echo "   supervisor"
sudo -u ${instance_name} mkdir /home/${instance_name}/supervisor

echo "   bin"
sudo -u ${instance_name} mkdir /home/${instance_name}/bin

echo "   tmp"
sudo -u ${instance_name} mkdir /home/${instance_name}/tmp

echo "   media"
sudo -u ${instance_name} mkdir /home/${instance_name}/media

echo "   private"
sudo -u ${instance_name} mkdir /home/${instance_name}/private
chmod 700 /home/${instance_name}/private


echo "   static"
sudo -u ${instance_name} ln -s  /home/${instance_name}/freyja/hirer/static /home/${instance_name}/static

echo "[OK]"


echo "Phase 10: Preparing Gunicorn"
cp start_gunicorn.sh /home/${instance_name}/gunicorn/
chmod +x /home/${instance_name}/gunicorn/start_gunicorn.sh
chown ${instance_name}.${instance_name} /home/${instance_name}/gunicorn/start_gunicorn.sh
sed -i s/"__SEDCHANGEIT_001__"/"${instance_name}"/g /home/${instance_name}/gunicorn/start_gunicorn.sh
echo "[OK]"


echo "Phase 11: Preparing Supervisor"

supervisor_conf_file=/etc/supervisor/conf.d/${instance_name}.conf
touch ${supervisor_conf_file}

echo "[program:${instance_name}]" >> ${supervisor_conf_file}
echo "command = /home/${instance_name}/gunicorn/start_gunicorn.sh" >> ${supervisor_conf_file}
echo "user = ${instance_name}" >> ${supervisor_conf_file}
echo "autostart = true" >> ${supervisor_conf_file}
echo "autorestart = true" >> ${supervisor_conf_file}
echo "stdout_logfile = /home/${instance_name}/logs/gunicorn.log" >> ${supervisor_conf_file}
echo "stderr_logfile = /home/${instance_name}/logs/gunicorn_err.log" >> ${supervisor_conf_file}
echo "environment=LANG=en_US.UTF-8,LC_ALL=en_US.UTF-8" >> ${supervisor_conf_file}

supervisorctl reread
supervisorctl update

echo "[OK]"


echo "Phase 11: Preparing Nginx"
nginx_conf_file=/etc/nginx/sites-available/${instance_name}
cp nginx_conf ${nginx_conf_file}
sed -i s/"__SEDCHANGEIT_001__"/"${instance_name}"/g ${nginx_conf_file}

ln -s ${nginx_conf_file} /etc/nginx/sites-enabled/${instance_name}
service nginx restart
echo "[OK]"


echo "Phase 12: Changing new user files permissions"
#chmod 400 /home/${instance_name}/freyja/pilates/local_settings.py
#touch /home/${instance_name}/freyja/pilates/local_settings.pyc
#chmod 400 /home/${instance_name}/freyja/pilates/local_settings.pyc
chmod 400 /home/${instance_name}/firstaccess
echo "[OK]"


echo "Phase 13: Updating Installed Instances Folder"
ln -s /home/${instance_name} ../installed_instances/${instance_name}
echo "[OK]"


echo "Work complete, bye!"
