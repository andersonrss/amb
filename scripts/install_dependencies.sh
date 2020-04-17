#!/bin/bash

echo Installing the necessary system dependencies to run Freyja...

# Verify if you are root ..
if [ "$(id -u)" != "0" ]; then
   echo "*** This script must be run as root... exiting" 1>&2
   exit 1
fi

apt-get update
apt-get install supervisor \
		nginx \
		libpq-dev \
		python-dev \
		virtualenv \
		python3-venv \
		git \
		sudo \
		gcc \

echo Done

