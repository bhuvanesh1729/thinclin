#!/bin/bash

# Script to install ThinClin Remote Access Tool
# Author: Cline
# Date: 2024-03-28
# GitHub: https://github.com/bhuvanesh1729/thinclin

# Exit on any error
set -e

echo "Starting ThinClin Installation..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Check if running on Ubuntu
if ! grep -q "Ubuntu" /etc/os-release; then
    echo "This script is designed for Ubuntu systems only"
    exit 1
fi

# Update package lists
echo "Updating package lists..."
apt-get update

# Install Node.js and npm from NodeSource
echo "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install required dependencies
echo "Installing dependencies..."
apt-get install -y \
    xrdp \
    xfce4 \
    xfce4-goodies \
    tightvncserver \
    net-tools \
    curl

# Verify Node.js and npm installation
echo "Verifying Node.js installation..."
node --version
npm --version

# Install LocalTunnel globally
echo "Installing LocalTunnel..."
npm install -g localtunnel --no-audit

# Configure XRDP to use custom port and XFCE
echo "Configuring XRDP..."
echo xfce4-session > ~/.xsession

# Configure XRDP to use port 1431
sed -i 's/port=3389/port=1431/g' /etc/xrdp/xrdp.ini

# Restart XRDP service
echo "Restarting XRDP service..."
service xrdp restart

# Configure firewall
echo "Configuring firewall..."
if command -v ufw >/dev/null 2>&1; then
    ufw allow 1431/tcp
    echo "Firewall rule added for RDP port 1431"
else
    echo "UFW not installed. Please configure your firewall manually to allow port 1431"
fi

# Create ThinClin configuration directory
echo "Setting up ThinClin configuration..."
mkdir -p /etc/thinclin
chmod 755 /etc/thinclin

# Create basic configuration file
cat > /etc/thinclin/config.conf << EOL
# ThinClin Configuration
allow_remote=true
encryption=true
session_timeout=3600
max_connections=10
log_level=info
EOL

# Set proper permissions
chmod 644 /etc/thinclin/config.conf

# Create LocalTunnel startup script
echo "Creating LocalTunnel startup script..."
cat > /usr/local/bin/start-thinclin-tunnel << EOL
#!/bin/bash
# Start LocalTunnel for ThinClin
lt --port 1431 --subdomain thinclin-\$(hostname | md5sum | cut -c1-8)
EOL

chmod +x /usr/local/bin/start-thinclin-tunnel

# Create systemd service for LocalTunnel
cat > /etc/systemd/system/thinclin-tunnel.service << EOL
[Unit]
Description=ThinClin LocalTunnel Service
After=network.target

[Service]
ExecStart=/usr/local/bin/start-thinclin-tunnel
Restart=always
User=root
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOL

# Enable and start the LocalTunnel service
systemctl enable thinclin-tunnel.service
systemctl start thinclin-tunnel.service

# Final steps and verification
echo "Verifying installation..."
if systemctl is-active --quiet xrdp; then
    echo "XRDP service is running"
    echo "ThinClin installation completed successfully!"
    echo "You can now connect to this machine using an RDP client"
    echo "Local IP Address: $(hostname -I | cut -d' ' -f1)"
    echo "Local Port: 1431"
    
    # Get and display the LocalTunnel URL
    echo -e "\nWaiting for LocalTunnel to start..."
    sleep 5
    if systemctl is-active --quiet thinclin-tunnel; then
        TUNNEL_URL=$(journalctl -u thinclin-tunnel.service -n 20 | grep -o 'https://.*\.loca\.lt' | tail -n 1)
        echo -e "\nLocalTunnel URL: ${TUNNEL_URL:-"Starting up... Check with 'journalctl -u thinclin-tunnel.service' in a few moments"}"
    else
        echo "Warning: LocalTunnel service is not running. Check logs with 'journalctl -u thinclin-tunnel.service'"
    fi
else
    echo "Warning: XRDP service is not running. Please check the logs for errors."
    exit 1
fi

# Security recommendations
echo -e "\nSecurity Recommendations:"
echo "1. Change default user password"
echo "2. Configure UFW firewall if not already set up"
echo "3. Use strong authentication methods"
echo "4. Regularly update the system"
echo "5. Consider setting up SSL for more secure connections"
