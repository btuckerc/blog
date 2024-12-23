#!/bin/bash

# Exit on any error
set -e

# Configuration
DOMAIN="btuckerc.com"
REPO_URL="https://github.com/btuckerc/Blog.git"
DEPLOY_DIR="/opt/blog"
PDS_DIR="/pds"

# Update system and install dependencies
echo "Installing dependencies..."
sudo apt update
sudo apt install -y docker.io docker-compose-plugin nginx certbot python3-certbot-nginx git

# Create necessary directories
echo "Creating directories..."
sudo mkdir -p $DEPLOY_DIR
sudo mkdir -p $PDS_DIR/caddy/data
sudo mkdir -p $PDS_DIR/caddy/etc/caddy
sudo mkdir -p $PDS_DIR/blocks

# Set up the blog directory
echo "Setting up blog repository..."
cd $DEPLOY_DIR
if [ ! -d ".git" ]; then
    git clone --branch public $REPO_URL .
fi

# Ensure proper permissions
sudo chown -R $USER:$USER $DEPLOY_DIR
sudo chown -R $USER:$USER $PDS_DIR

# Start Docker service if not running
echo "Ensuring Docker is running..."
if ! systemctl is-active --quiet docker; then
    sudo systemctl enable docker
    sudo systemctl start docker
fi

# Pull latest Docker images
echo "Pulling latest Docker images..."
sudo docker compose pull

# Start or restart services
echo "Starting services..."
sudo docker compose down || true  # Don't fail if services weren't running
sudo docker compose up -d

# Configure firewall
echo "Configuring firewall..."
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 22  # Ensure SSH access is maintained
sudo ufw --force enable
sudo ufw reload

# Set up SSL certificates if not already configured
if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "Setting up SSL certificates..."
    sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email tucker@btuckerc.com
fi

echo "Deployment complete! Services status:"
sudo docker compose ps

# Add a daily cron job to renew SSL certificates if it doesn't exist
if ! crontab -l | grep -q "certbot renew"; then
    (crontab -l 2>/dev/null; echo "0 0 * * * /usr/bin/certbot renew --quiet") | crontab -
fi
