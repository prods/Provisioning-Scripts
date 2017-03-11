#!/bin/bash

# Inlcude tools
. tools.sh
# VARIABLES
SENTRY_USER=sentry
SENTRY_HOST=`get_eth0_ip`
SENTRY_DB_HOST=$SENTRY_HOST
SENTRY_DB=sentry_db
SENTRY_DB_USER=$SENTRY_USER
SENTRY_DB_USER_PASSWORD="`get_hash`"
SENTRY_CONFIG_FILE=/home/$SENTRY_USER/.sentry/sentry.conf.py
SENTRY_WORKERS_SCRIPT=/usr/local/bin/start_sentry_workers
SENTRY_WEB_SCRIPT=/usr/local/bin/start_sentry_webui

# Create Sentry User
sudo adduser $SENTRY_USER
sudo adduser $SENTRY_USER sudo
# Install Pre-requirements
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install build-essential python-setuptools python-dev libffi-dev libxml2-dev libxslt1-dev python-pip nginx supervisor -y
# Install Postgresql
sudo ./postgres.sh
# Install Redis
sudo ./redis.sh
# Install psycopg2
sudo pip install psycopg2
# Install Pillow Dependencies
sudo apt-get install python-imaging libjpeg8 libjpeg62-dev libfreetype6 libfreetype6-dev
# Install Sentry
sudo pip install sentry
# Create database and user
sudo -u postgres psql -U postgres -d postgres -c "CREATE DATABASE $SENTRY_DB;"
sudo -u postgres psql -U postgres -d postgres -c "CREATE USER $SENTRY_DB_USER WITH ENCRYPTED PASSWORD '$SENTRY_DB_USER_PASSWORD';"
sudo -u postgres psql -U postgres -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE $SENTRY_DB TO $SENTRY_DB_USER;"
#
# SENTRY SETUP
#
# Initialize config file
SENTRY_CONFIG_SETUP_SED="s|'ENGINE': 'django.db.backends.sqlite3'|'ENGINE': 'django.db.backends.postgresql_psycopg2'|g;s|'NAME': os.path.join(CONF_ROOT, 'sentry.db')|'NAME': '$SENTRY_DB'|g;s|'USER': 'postgres'|'USER': '$SENTRY_USER'|g;s|'PASSWORD': ''|'PASSWORD': '$SENTRY_DB_USER_PASSWORD'|g;s|'HOST': ''|'HOST': '$SENTRY_DB_HOST'|g;s|'PORT': ''|'PORT': '5432'|g;s|SENTRY_URL_PREFIX = 'http://sentry.example.com'|SENTRY_URL_PREFIX = 'http://$SENTRY_HOST'|g"
SENTRY_CONFIG_SETUP_CMD=`echo -e "sentry init
sed -i.bak \"$SENTRY_CONFIG_SETUP_SED\" $SENTRY_CONFIG_FILE
# Initialize databases
sentry upgrade"`
# Apply configuration file changes
su - $SENTRY_USER -c "$SENTRY_CONFIG_SETUP_CMD"
#
# SETUP WEB INTERFACE USIN nginx
#
sudo rm /etc/nginx/sites-enabled/default
echo -e "server {
    # listen on port 80
    listen 80;

    # for requests to these domains
    server_name $SENTRY_HOST;

    # keep logs in these files
    access_log /var/log/nginx/sentry.access.log;
    error_log /var/log/nginx/sentry.error.log;

    location / {
        proxy_pass http://localhost:9000;
        proxy_redirect off;

        proxy_read_timeout 5m;

        # make sure these HTTP headers are set properly
        proxy_set_header Host            \$host;
        proxy_set_header X-Real-IP       \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}" | sudo tee -a /etc/nginx/sites-available/sentry
cd /etc/nginx/sites-enabled
sudo ln -s ../sites-available/sentry
# Restart Nginx Service
sudo service nginx restart
#
# SETUP SUPERVISORD SERVICES
#
# Create Workers Service
SENTRY_WORKERS_SCRIPT_SRC="#!/bin/bash\n/usr/local/bin/sentry --config=/home/$SENTRY_USER/.sentry/sentry.conf.py celery worker -B"
echo -e "$SENTRY_WORKERS_SCRIPT_SRC" | sudo tee -a $SENTRY_WORKERS_SCRIPT
sudo chmod +x $SENTRY_WORKERS_SCRIPT
SENTRY_WORKERS_SUPERVISOR_CONF="[program:sentry-workers]
command=\"$SENTRY_WORKERS_SCRIPT\"
directory=/home/$SENTRY_USER
autostart=true
autorestart=true
startretries=3
stderr_logfile=/var/log/supervisor/sentry_workers.err.log
stdout_logfile=/var/log/supervisor/sentry_workers.out.log
user=$SENTRY_USER"
echo -e "$SENTRY_WORKERS_SUPERVISOR_CONF" | sudo tee -a /etc/supervisor/conf.d/sentryworkers.conf
# Create Web Interfaces Service
SENTRY_WEB_SCRIPT_SRC="#!/bin/bash\n/usr/local/bin/sentry --config=/home/$SENTRY_USER/.sentry/sentry.conf.py start http"
echo -e "$SENTRY_WEB_SCRIPT_SRC" | sudo tee -a $SENTRY_WEB_SCRIPT
sudo chmod +x $SENTRY_WEB_SCRIPT
SENTRY_WEB_SUPERVISOR_CONF="[program:sentry-web]
command=\"$SENTRY_WEB_SCRIPT\"
directory=/home/$SENTRY_USER
autostart=true
autorestart=true
startretries=3
stderr_logfile=/var/log/supervisor/sentry_web.err.log
stdout_logfile=/var/log/supervisor/sentry_web.out.log
user=$SENTRY_USER"
echo -e "$SENTRY_WEB_SUPERVISOR_CONF" | sudo tee -a /etc/supervisor/conf.d/sentryweb.conf

# Start Services
sudo killall supervisord
sudo supervisord
