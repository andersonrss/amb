#!/bin/bash

INSTANCE=__SEDCHANGEIT_001__
HOME=/home/${INSTANCE}

NAME="${INSTANCE}"                                # Name of the application
DJANGODIR=${HOME}/freyja                          # Django project directory
SOCKFILE=${HOME}/gunicorn/gu.sock                 # we will communicte using this unix socket
USER=${INSTANCE}                                  # the user to run as
GROUP=${INSTANCE}                                 # the group to run as
NUM_WORKERS=3                                     # how many worker processes should Gunicorn spawn
DJANGO_SETTINGS_MODULE=solos_match.settings           # which settings file should Django use
DJANGO_WSGI_MODULE=solos_match.wsgi                   # WSGI module name

echo "Starting $NAME as `whoami`"

# Activate the virtual environment
cd $DJANGODIR
source ${HOME}/venv/bin/activate
export DJANGO_SETTINGS_MODULE=$DJANGO_SETTINGS_MODULE
export PYTHONPATH=$DJANGODIR:$PYTHONPATH

# Create the run directory if it doesn't exist
RUNDIR=$(dirname $SOCKFILE)
test -d $RUNDIR || mkdir -p $RUNDIR

# Start your Django Unicorn
# Programs meant to be run under supervisor should not daemonize themselves (do not use --daemon)
exec gunicorn ${DJANGO_WSGI_MODULE}:application \
  --name $NAME \
  --workers $NUM_WORKERS \
  --user=$USER --group=$GROUP \
  --bind=unix:$SOCKFILE \
  --log-level=debug \
  --log-file=-
