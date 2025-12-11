#!/bin/bash
# Cowrie Honeypot Deployment Script
# This script automates the deployment of Cowrie on a fresh server

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Cowrie Honeypot Deployment Script ===${NC}"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}Error: Do not run this script as root!${NC}"
    echo "This script will create a dedicated 'cowrie' user and use sudo when needed."
    exit 1
fi

# Function to print status messages
print_status() {
    echo -e "${GREEN}[*]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Step 1: Update system and install dependencies
print_status "Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y git python3-pip python3-venv libssl-dev libffi-dev \
    build-essential libpython3-dev python3-minimal authbind iptables

# Step 2: Create cowrie user if it doesn't exist
if id "cowrie" &>/dev/null; then
    print_warning "User 'cowrie' already exists, skipping user creation"
else
    print_status "Creating dedicated 'cowrie' user..."
    sudo adduser --disabled-password --gecos "" cowrie
fi

# Step 3: Clone Cowrie repository
print_status "Cloning Cowrie repository..."
COWRIE_DIR="/home/cowrie/cowrie"

if [ -d "$COWRIE_DIR" ]; then
    print_warning "Cowrie directory already exists, pulling latest changes..."
    sudo -u cowrie git -C "$COWRIE_DIR" pull
else
    sudo -u cowrie git clone https://github.com/cowrie/cowrie.git "$COWRIE_DIR"
fi

# Step 4: Setup Python virtual environment
print_status "Setting up Python virtual environment..."
sudo -u cowrie python3 -m venv "$COWRIE_DIR/cowrie-env"
sudo -u cowrie "$COWRIE_DIR/cowrie-env/bin/python" -m pip install --upgrade pip
sudo -u cowrie "$COWRIE_DIR/cowrie-env/bin/python" -m pip install -e "$COWRIE_DIR"

# Step 5: Copy configuration files
print_status "Configuring Cowrie..."

# Copy our custom config if it exists
if [ -f "cowrie/etc/cowrie.cfg" ]; then
    sudo cp cowrie/etc/cowrie.cfg "$COWRIE_DIR/etc/cowrie.cfg"
    sudo chown cowrie:cowrie "$COWRIE_DIR/etc/cowrie.cfg"
    print_status "Custom configuration applied"
fi

# Copy userdb if it exists
if [ -f "cowrie/etc/userdb.txt" ]; then
    sudo cp cowrie/etc/userdb.txt "$COWRIE_DIR/etc/userdb.txt"
    sudo chown cowrie:cowrie "$COWRIE_DIR/etc/userdb.txt"
    print_status "Custom userdb applied"
fi

# Step 6: Setup authbind for port 22 (optional)
read -p "Do you want to configure Cowrie to listen on port 22 (SSH)? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Setting up authbind for port 22..."
    sudo touch /etc/authbind/byport/22
    sudo chown cowrie:cowrie /etc/authbind/byport/22
    sudo chmod 770 /etc/authbind/byport/22
    
    # Update config to listen on port 22
    sudo -u cowrie sed -i 's/tcp:2222:interface=0.0.0.0/tcp:22:interface=0.0.0.0/' "$COWRIE_DIR/etc/cowrie.cfg"
    print_status "Cowrie configured to listen on port 22"
else
    print_status "Cowrie will listen on port 2222 (default)"
    print_warning "You can use iptables to redirect port 22 to 2222:"
    echo "  sudo iptables -t nat -A PREROUTING -p tcp --dport 22 -j REDIRECT --to-port 2222"
fi

# Step 7: Setup authbind for port 23 (Telnet, optional)
read -p "Do you want to configure Cowrie to listen on port 23 (Telnet)? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Setting up authbind for port 23..."
    sudo touch /etc/authbind/byport/23
    sudo chown cowrie:cowrie /etc/authbind/byport/23
    sudo chmod 770 /etc/authbind/byport/23
    
    # Update config to listen on port 23
    sudo -u cowrie sed -i 's/tcp:2223:interface=0.0.0.0/tcp:23:interface=0.0.0.0/' "$COWRIE_DIR/etc/cowrie.cfg"
    print_status "Cowrie configured to listen on port 23"
fi

# Step 8: Create systemd service
print_status "Creating systemd service..."
sudo tee /etc/systemd/system/cowrie.service > /dev/null <<EOF
[Unit]
Description=Cowrie SSH/Telnet Honeypot
After=network.target
Documentation=https://docs.cowrie.org

[Service]
Type=forking
User=cowrie
Group=cowrie
WorkingDirectory=/home/cowrie/cowrie
ExecStart=/home/cowrie/cowrie/bin/cowrie start
ExecStop=/home/cowrie/cowrie/bin/cowrie stop
Environment="AUTHBIND_ENABLED=yes"
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable cowrie.service

# Step 9: Setup log rotation
print_status "Setting up log rotation..."
sudo tee /etc/logrotate.d/cowrie > /dev/null <<EOF
/home/cowrie/cowrie/var/log/cowrie/*.log /home/cowrie/cowrie/var/log/cowrie/*.json {
    daily
    rotate 30
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
    su cowrie cowrie
}
EOF

# Step 10: Start Cowrie
print_status "Starting Cowrie honeypot..."
sudo systemctl start cowrie.service

# Wait a moment for startup
sleep 3

# Check status
if sudo systemctl is-active --quiet cowrie.service; then
    print_status "${GREEN}SUCCESS!${NC} Cowrie is running!"
    echo ""
    echo "=== Deployment Summary ==="
    echo "Installation directory: $COWRIE_DIR"
    echo "Log files: $COWRIE_DIR/var/log/cowrie/"
    echo "Downloaded files: $COWRIE_DIR/var/lib/cowrie/downloads/"
    echo ""
    echo "Useful commands:"
    echo "  sudo systemctl status cowrie   # Check status"
    echo "  sudo systemctl stop cowrie     # Stop honeypot"
    echo "  sudo systemctl start cowrie    # Start honeypot"
    echo "  sudo systemctl restart cowrie  # Restart honeypot"
    echo "  tail -f $COWRIE_DIR/var/log/cowrie/cowrie.log  # View logs"
    echo ""
    echo "To view captured sessions:"
    echo "  cd $COWRIE_DIR"
    echo "  ./bin/playlog var/lib/cowrie/tty/*.log"
else
    print_error "Cowrie failed to start. Check logs:"
    echo "  sudo journalctl -u cowrie.service -n 50"
    echo "  tail -n 50 $COWRIE_DIR/var/log/cowrie/cowrie.log"
    exit 1
fi

print_status "Deployment complete!"

