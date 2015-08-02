#!/bin/bash
# Include tools
. tools.sh
# Variables
REDIS_ROOT_PATH=/etc/redis
REDIS_CONFIG_FILE_PATH=$REDIS_ROOT_PATH/redis.conf
REDIS_INSTALLED=`ls /etc/redis`
IP=`get_eth0_ip`

if [ "$REDIS_INSTALLED" != "" ]; then
  echo "REDIS was found. Operation aborted."
else
# Install Redis
sudo apt-get install redis-server -y

# Open Port
sudo cp -f $REDIS_CONFIG_FILE_PATH $REDIS_CONFIG_FILE_PATH.backup
sudo sed "s/bind 127.0.0.1/bind 127.0.0.1 $IP/g" $REDIS_CONFIG_FILE_PATH.backup > $REDIS_CONFIG_FILE_PATH

# Apply Changes: Restart Service
sudo service redis-server restart
fi
