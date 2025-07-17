#!/bin/bash

set -e

# Update system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install required packages
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Remove incompatible Docker packages
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
    sudo apt-get remove -y $pkg 2>/dev/null || true
done

# Install Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

# Create project directory
sudo mkdir -p /opt/n8n
cd /opt/n8n

# Create .env file
sudo tee .env << EOF
# DOMAIN_NAME and SUBDOMAIN together determine where n8n will be reachable from
DOMAIN_NAME=${domain_name}
SUBDOMAIN=${subdomain}
GENERIC_TIMEZONE=${timezone}
SSL_EMAIL=${ssl_email}

# Database configuration
POSTGRES_PASSWORD=${db_password}
EOF

# Create docker-compose.yml
sudo tee docker-compose.yml << 'EOF'
version: '3.8'

services:
  traefik:
    image: "traefik:latest"
    restart: unless-stopped
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entrypoint.scheme=https"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.mytlschallenge.acme.tlschallenge=true"
      - "--certificatesresolvers.mytlschallenge.acme.email=$${SSL_EMAIL}"
      - "--certificatesresolvers.mytlschallenge.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - traefik_data:/letsencrypt
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - n8n_network

  postgres:
    image: postgres:15
    restart: unless-stopped
    environment:
      POSTGRES_USER: n8n
      POSTGRES_PASSWORD: $${POSTGRES_PASSWORD}
      POSTGRES_DB: n8n
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - n8n_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U n8n"]
      interval: 5s
      timeout: 5s
      retries: 5

  n8n:
    image: docker.n8n.io/n8nio/n8n:latest
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    labels:
      - traefik.enable=true
      - traefik.http.routers.n8n.rule=Host(`$${SUBDOMAIN}.$${DOMAIN_NAME}`)
      - traefik.http.routers.n8n.tls=true
      - traefik.http.routers.n8n.entrypoints=web,websecure
      - traefik.http.routers.n8n.tls.certresolver=mytlschallenge
      - traefik.http.middlewares.n8n.headers.SSLRedirect=true
      - traefik.http.middlewares.n8n.headers.STSSeconds=315360000
      - traefik.http.middlewares.n8n.headers.browserXSSFilter=true
      - traefik.http.middlewares.n8n.headers.contentTypeNosniff=true
      - traefik.http.middlewares.n8n.headers.forceSTSHeader=true
      - traefik.http.middlewares.n8n.headers.STSIncludeSubdomains=true
      - traefik.http.middlewares.n8n.headers.STSPreload=true
      - traefik.http.routers.n8n.middlewares=n8n@docker
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=$${POSTGRES_PASSWORD}
      - N8N_HOST=$${SUBDOMAIN}.$${DOMAIN_NAME}
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - WEBHOOK_URL=https://$${SUBDOMAIN}.$${DOMAIN_NAME}/
      - GENERIC_TIMEZONE=$${GENERIC_TIMEZONE}
    volumes:
      - n8n_data:/home/node/.n8n
      - ./local-files:/files
    networks:
      - n8n_network

volumes:
  postgres_data:
  n8n_data:
  traefik_data:

networks:
  n8n_network:
    driver: bridge
EOF

# Create local-files directory
sudo mkdir -p local-files

# Set proper permissions
sudo chown -R $USER:$USER /opt/n8n
sudo chmod +x /opt/n8n

# Start services
cd /opt/n8n
sudo docker compose up -d

# Wait for services to be ready
sleep 30

# Check if services are running
if sudo docker compose ps | grep -q "Up"; then
    echo "n8n deployment completed successfully!"
    echo "n8n will be available at: https://${subdomain}.${domain_name}"
else
    echo "Some services failed to start. Check logs with: sudo docker compose logs"
fi