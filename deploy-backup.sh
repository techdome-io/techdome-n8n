#!/bin/bash

set -e

echo "==============================================="
echo "          n8n Ubuntu 22 Deployment Script"
echo "==============================================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Collect user input for environment variables
echo "Please provide the following information for your n8n deployment:"
echo

read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME
while [[ -z "$DOMAIN_NAME" ]]; do
    print_warning "Domain name cannot be empty!"
    read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME
done

read -p "Enter subdomain for n8n (e.g., n8n): " SUBDOMAIN
while [[ -z "$SUBDOMAIN" ]]; do
    print_warning "Subdomain cannot be empty!"
    read -p "Enter subdomain for n8n (e.g., n8n): " SUBDOMAIN
done

read -p "Enter your email for SSL certificate (e.g., user@example.com): " SSL_EMAIL
while [[ -z "$SSL_EMAIL" ]]; do
    print_warning "Email cannot be empty!"
    read -p "Enter your email for SSL certificate (e.g., user@example.com): " SSL_EMAIL
done

read -p "Enter timezone (default: Asia/Kolkata): " GENERIC_TIMEZONE
GENERIC_TIMEZONE=${GENERIC_TIMEZONE:-"Asia/Kolkata"}

echo
print_info "Configuration Summary:"
print_info "Domain: ${SUBDOMAIN}.${DOMAIN_NAME}"
print_info "Email: ${SSL_EMAIL}"
print_info "Timezone: ${GENERIC_TIMEZONE}"
echo

read -p "Continue with installation? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    print_info "Installation cancelled."
    exit 0
fi

echo
print_info "Starting n8n deployment..."

# Step 1: Install Docker and Docker Compose
print_info "Step 1: Installing Docker and Docker Compose..."

# Remove incompatible Docker packages
print_info "Removing incompatible Docker packages..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
    sudo apt-get remove -y $pkg 2>/dev/null || true
done

# Install prerequisites
print_info "Installing prerequisites..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl

# Download Docker GPG key
print_info "Setting up Docker repository..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Configure Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker and Docker Compose
print_info "Installing Docker and Docker Compose..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify installation
print_info "Verifying Docker installation..."
docker --version
docker compose version

# Step 2: Configure non-root user access
print_info "Step 2: Configuring Docker access for current user..."
sudo usermod -aG docker ${USER}

print_warning "Docker group membership added. You may need to log out and back in for changes to take effect."
print_info "For now, using sudo for Docker commands during installation..."

# Step 3: Install Node.js and n8n CLI
print_info "Step 3: Installing Node.js and n8n CLI..."

# Function to source NVM
source_nvm() {
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}

# Check if nvm is already installed
if ! command -v nvm &> /dev/null && [[ ! -f "$HOME/.nvm/nvm.sh" ]]; then
    print_info "Installing NVM (Node Version Manager)..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    
    # Source nvm for current session
    source_nvm
else
    print_info "NVM already installed"
    # Source nvm for current session
    source_nvm
fi

# Verify NVM is loaded
if ! command -v nvm &> /dev/null; then
    print_error "Failed to load NVM. Please run the script again or restart your terminal."
    exit 1
fi

# Install Node.js 22
print_info "Installing Node.js 22..."
nvm install 22
nvm use 22

# Verify Node.js installation
print_info "Verifying Node.js installation..."
node -v
nvm current

# Install n8n CLI globally
print_info "Installing n8n CLI globally..."
npm install -g n8n

# Verify n8n installation
print_info "Verifying n8n CLI installation..."
n8n --version

# Add NVM to user's shell profile for future sessions
print_info "Adding NVM to shell profile for future sessions..."
if ! grep -q "NVM_DIR" "$HOME/.bashrc"; then
    echo '' >> "$HOME/.bashrc"
    echo '# Load NVM' >> "$HOME/.bashrc"
    echo 'export NVM_DIR="$HOME/.nvm"' >> "$HOME/.bashrc"
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$HOME/.bashrc"
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> "$HOME/.bashrc"
fi

# Also add to .profile if it exists
if [[ -f "$HOME/.profile" ]] && ! grep -q "NVM_DIR" "$HOME/.profile"; then
    echo '' >> "$HOME/.profile"
    echo '# Load NVM' >> "$HOME/.profile"
    echo 'export NVM_DIR="$HOME/.nvm"' >> "$HOME/.profile"
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$HOME/.profile"
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> "$HOME/.profile"
fi

# Step 4: Create project directory and files
print_info "Step 4: Creating project directory and configuration files..."

# Create project directory
PROJECT_DIR="$HOME/n8n-compose"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Create local-files directory
mkdir -p local-files

# Create .env file
print_info "Creating .env configuration file..."
cat > .env << EOF
# DOMAIN_NAME and SUBDOMAIN together determine where n8n will be reachable from
# The top level domain to serve from
DOMAIN_NAME=${DOMAIN_NAME}

# The subdomain to serve from
SUBDOMAIN=${SUBDOMAIN}

# The above example serve n8n at: https://${SUBDOMAIN}.${DOMAIN_NAME}

# Optional timezone to set which gets used by Cron and other scheduling nodes
GENERIC_TIMEZONE=${GENERIC_TIMEZONE}

# The email address to use for the TLS/SSL certificate creation
SSL_EMAIL=${SSL_EMAIL}
EOF

# Create Docker Compose file
print_info "Creating Docker Compose configuration..."
cat > compose.yaml << 'EOF'
services:
  traefik:
    image: "traefik"
    restart: always
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entrypoint.scheme=https"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.mytlschallenge.acme.tlschallenge=true"
      - "--certificatesresolvers.mytlschallenge.acme.email=${SSL_EMAIL}"
      - "--certificatesresolvers.mytlschallenge.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - traefik_data:/letsencrypt
      - /var/run/docker.sock:/var/run/docker.sock:ro

  postgres:
    image: postgres:15
    restart: always
    environment:
      POSTGRES_USER: n8n
      POSTGRES_PASSWORD: n8npass
      POSTGRES_DB: n8n
    volumes:
      - postgres_data:/var/lib/postgresql/data

  n8n:
    image: docker.n8n.io/n8nio/n8n
    restart: always
    ports:
      - "127.0.0.1:5678:5678"
    labels:
      - traefik.enable=true
      - traefik.http.routers.n8n.rule=Host(`${SUBDOMAIN}.${DOMAIN_NAME}`)
      - traefik.http.routers.n8n.tls=true
      - traefik.http.routers.n8n.entrypoints=web,websecure
      - traefik.http.routers.n8n.tls.certresolver=mytlschallenge
      - traefik.http.middlewares.n8n.headers.SSLRedirect=true
      - traefik.http.middlewares.n8n.headers.STSSeconds=315360000
      - traefik.http.middlewares.n8n.headers.browserXSSFilter=true
      - traefik.http.middlewares.n8n.headers.contentTypeNosniff=true
      - traefik.http.middlewares.n8n.headers.forceSTSHeader=true
      - traefik.http.middlewares.n8n.headers.SSLHost=${DOMAIN_NAME}
      - traefik.http.middlewares.n8n.headers.STSIncludeSubdomains=true
      - traefik.http.middlewares.n8n.headers.STSPreload=true
      - traefik.http.routers.n8n.middlewares=n8n@docker
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=n8npass
      - N8N_HOST=${SUBDOMAIN}.${DOMAIN_NAME}
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - WEBHOOK_URL=https://${SUBDOMAIN}.${DOMAIN_NAME}/
      - GENERIC_TIMEZONE=${GENERIC_TIMEZONE}
    volumes:
      - n8n_data:/home/node/.n8n
      - ./local-files:/files

volumes:
  postgres_data:
  n8n_data:
  traefik_data:
EOF

# Step 5: Start n8n
print_info "Step 5: Starting n8n with Docker Compose..."

# Start the services
sudo docker compose up -d

print_info "Waiting for services to start..."
sleep 10

# Check if containers are running
if sudo docker compose ps | grep -q "Up"; then
    print_info "✅ n8n deployment completed successfully!"
    echo
    print_info "Your n8n instance will be available at: https://${SUBDOMAIN}.${DOMAIN_NAME}"
    print_info "Project directory: ${PROJECT_DIR}"
    echo
    print_info "To manage your n8n instance:"
    print_info "  - Stop:    cd ${PROJECT_DIR} && sudo docker compose stop"
    print_info "  - Start:   cd ${PROJECT_DIR} && sudo docker compose up -d"
    print_info "  - Logs:    cd ${PROJECT_DIR} && sudo docker compose logs -f"
    print_info "  - Status:  cd ${PROJECT_DIR} && sudo docker compose ps"
    echo
    print_info "To import workflows:"
    print_info "  - With n8n CLI: python3 import_workflows.py (requires NVM/Node.js)"
    print_info "  - With API:     python3 import_workflows_api.py -u https://${SUBDOMAIN}.${DOMAIN_NAME}"
    print_info "  - Place workflow JSON files in ./workflows/ directory"
    echo
    print_warning "Note: Make sure your DNS A record points ${SUBDOMAIN}.${DOMAIN_NAME} to this server's IP address."
    print_warning "SSL certificate generation may take a few minutes on first access."
    print_warning "For NVM/Node.js to work in new sessions, restart your terminal or run: source ~/.bashrc"
else
    print_error "❌ Some services failed to start. Check logs with: cd ${PROJECT_DIR} && sudo docker compose logs"
    exit 1
fi

echo
print_info "Deployment script completed!"