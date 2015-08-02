USER=$1
PASSWORD=$2
# Install Rabbitmq
sudo apt-get install rabbitmq-server
# Setup Web Management
sudo rabbitmq-plugins enable rabbitmq_management
# Setup user
 sudo rabbitmqctl add_user $USER $PASSWORD
 sudo rabbitmqctl set_user_tags $USER administrator
 sudo rabbitmqctl set_permissions -p / $USER ".*" ".*" ".*"
# Now navigate to http://server-name:15672/
