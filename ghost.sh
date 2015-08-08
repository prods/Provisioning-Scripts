#!/bin/bash
GHOST_HOST=$1
GHOST_THEME=$2
GHOST_APP_SCRIPT=/usr/local/bin/start_ghost

# Prepare
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y build-essential supervisor nginx zip git-core

# Install node
curl --silent --location https://deb.nodesource.com/setup_0.12 | sudo bash -
sudo apt-get install --yes nodejs
#sudo ln -s /usr/bin/nodejs /usr/bin/node

# Install Ghost
sudo mkdir -p /var/www/
cd /var/www/
sudo wget https://ghost.org/zip/ghost-latest.zip
sudo unzip -d ghost ghost-latest.zip
cd ghost/
sudo npm install --production

# Configure Ghost
sudo cp config.example.js config.js
sudo sed -i.bak "s|url: 'http://my-ghost-blog.com'|url: 'http://$GHOST_HOST'|g" config.js

# Create Ghost User
sudo adduser --shell /bin/bash --gecos "ghost" ghost
sudo chown -R ghost:ghost /var/www/ghost/

# Create Nginx site
sudo rm /etc/nginx/sites-enabled/default
echo -e "server {
    # listen on port 80
    listen 80;

    # for requests to these domains
    server_name $GHOST_HOST;

    # keep logs in these files
    access_log /var/log/nginx/sentry.access.log;
    error_log /var/log/nginx/sentry.error.log;

    location / {
        proxy_pass http://localhost:2368;
        proxy_redirect off;

        proxy_read_timeout 5m;

        # make sure these HTTP headers are set properly
        proxy_set_header Host            \$host;
        proxy_set_header X-Real-IP       \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}" | sudo tee -a /etc/nginx/sites-available/ghost
cd /etc/nginx/sites-enabled
sudo ln -s ../sites-available/ghost
# Restart Nginx Service
sudo service nginx restart


# Create Web Interfaces Service
GHOST_APP_SCRIPT_SRC="#!/bin/bash\nnpm start --production"
echo -e "$GHOST_APP_SCRIPT_SRC" | sudo tee -a $GHOST_APP_SCRIPT
sudo chmod +x $GHOST_APP_SCRIPT
GHOST_APP_SUPERVISOR_CONF="[program:ghost-app]
command=\"$GHOST_APP_SCRIPT\"
directory=/var/www/ghost
autostart=true
autorestart=true
startretries=3
stderr_logfile=/var/log/supervisor/ghost.err.log
stdout_logfile=/var/log/supervisor/ghost.out.log
user=ghost"
echo -e "$GHOST_APP_SUPERVISOR_CONF" | sudo tee -a /etc/supervisor/conf.d/ghost.conf

# Install Theme if specified
if [ -z "$GHOST_THEME" ]; then
  cd /var/www/ghost/content/themes
  sudo git clone $GHOST_THEME
  sudo chown ghost:ghost -R .
fi

# Start Services
sudo killall supervisord
sudo supervisord
