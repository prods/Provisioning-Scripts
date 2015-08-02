#!/bin/bash

# Load Tools
. tools.sh

PG_VERSION=9.4
PG_ROOT_PATH=/etc/postgresql/$PG_VERSION/main
PG_HBA_FILE_PATH=$PG_ROOT_PATH/pg_hba.conf
PG_CONFIG_FILE_PATH=$PG_ROOT_PATH/postgresql.conf
PG_ALREADY_INSTALLED=`ls /etc/postgresql`

if [[ "$PG_ALREADY_INSTALLED" != "" ]]; then
  echo "POSTGRESQL $PG_ALREADY_INSTALLED was found. Operation aborted."
else

# Get IP
IP=`get_eth0_ip`
IP_NET=`echo "$IP" | cut -d"." -f1-3`.0

# Install Postgresql
sudo apt-get install postgresql postgresql-contrib libpq-dev postgresql-server-dev-$PG_VERSION -y

# Trust local network
cp -f $PG_CONFIG_FILE_PATH $PG_CONFIG_FILE_PATH.backup
echo "host    all     all        $IP_NET/24                 trust" | tee -a $PG_HBA_FILE_PATH
# Open Port
sudo cp -f $PG_CONFIG_FILE_PATH $PG_CONFIG_FILE_PATH.backup
sudo sed "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" $PG_CONFIG_FILE_PATH.backup > $PG_CONFIG_FILE_PATH

# Change postgres user password
sudo -u postgres psql -U postgres -d postgres -c "alter user postgres with password 'postgres';"
# Create PL/PGSQL Language
# sudo -u postgres psql -U postgres -d postgres -c "CREATE OR REPLACE LANGUAGE plpgsql;"
# Add AdminPack Extension
sudo -u postgres psql -U postgres -d postgres -c "CREATE EXTENSION \"adminpack\";"
# Apply Changes: Restart Service
sudo service postgresql restart

fi
