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

# Install Node.js and npm
echo "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install required system dependencies
echo "Installing system dependencies..."
apt-get install -y \
    xrdp \
    xfce4 \
    xfce4-goodies \
    tightvncserver \
    net-tools \
    curl \
    build-essential \
    python3 \
    expect

# Verify Node.js installation
echo "Verifying Node.js installation..."
if ! command -v node &> /dev/null; then
    echo "Node.js installation failed. Trying alternative method..."
    # Alternative Node.js installation using n
    curl -L https://raw.githubusercontent.com/tj/n/master/bin/n -o n
    bash n lts
    # Add to PATH
    export PATH="$PATH:/usr/local/bin/node"
fi

# Verify and fix npm installation
echo "Verifying npm installation..."
if ! command -v npm &> /dev/null; then
    echo "npm not found. Installing npm..."
    curl -L https://www.npmjs.com/install.sh | sh
fi

# Install required npm dependencies
echo "Installing npm dependencies..."
npm install -g \
    node-agent-base \
    node-archy \
    node-cacache \
    node-chalk \
    node-cli-table3 \
    node-columnify \
    node-cssesc \
    node-debug \
    node-emoji-regex \
    node-gyp \
    node-http-proxy-agent \
    node-https-proxy-agent \
    node-mkdirp \
    node-ms \
    node-nopt \
    node-normalize-package-data \
    node-npm-bundled \
    node-npm-normalize-package-bin \
    node-npm-package-arg \
    node-npmlog \
    node-postcss-selector-parser \
    node-read-package-json \
    node-rimraf \
    node-semver \
    node-string-width \
    node-strip-ansi \
    node-tar \
    node-validate-npm-package-name \
    node-which

# Install LocalTunnel globally
echo "Installing LocalTunnel..."
npm cache clean -f
npm install -g localtunnel --no-audit --force

# Configure display managers for coexistence
echo "Configuring display managers..."

# Disable display manager check in all init scripts
echo "Disabling display manager checks..."
for dm in lightdm gdm3 xdm; do
    if [ -f "/etc/init.d/$dm" ]; then
        echo "Modifying $dm init script..."
        cp "/etc/init.d/$dm" "/etc/init.d/$dm.backup"
        sed -i 's/\[ -x "$DEFAULT_DISPLAY_MANAGER_FILE" \]/false/g' "/etc/init.d/$dm"
    fi
done

# Stop all display managers
echo "Stopping display managers..."
systemctl stop lightdm gdm3 xdm 2>/dev/null || true

# Remove any existing display manager configuration
echo "Cleaning up display manager configuration..."
rm -f /etc/X11/default-display-manager

# Configure LightDM
if [ -f /etc/init.d/lightdm ]; then
    echo "Configuring LightDM..."
    
    # Create LightDM configuration directory if it doesn't exist
    mkdir -p /etc/lightdm/lightdm.conf.d

    # Configure LightDM with strict display settings
    cat > /etc/lightdm/lightdm.conf.d/70-thinclin.conf << EOL
[LightDM]
minimum-display-number=0
maximum-display-number=0
user-session=xfce
allow-guest=false
greeter-session=lightdm-gtk-greeter
xserver-command=X -ac :0 -nolisten tcp
display-setup-script=/usr/local/bin/lightdm-display-setup
[Seat:*]
xserver-layout=default
xserver-config=xorg.conf.lightdm
type=xlocal
EOL

    # Create display setup script for LightDM
    cat > /usr/local/bin/lightdm-display-setup << EOL
#!/bin/bash
# Set up X server for LightDM with specific configuration
X -ac :0 -nolisten tcp -config /etc/X11/xorg.conf.lightdm &
sleep 2
EOL
    chmod +x /usr/local/bin/lightdm-display-setup

    # Create specific X configuration for LightDM
    cat > /etc/X11/xorg.conf.lightdm << EOL
Section "ServerLayout"
    Identifier     "LightDM Layout"
    Screen      0  "Screen0" 0 0
EndSection

Section "Monitor"
    Identifier   "Monitor0"
    Option      "DPMS" "true"
EndSection

Section "Device"
    Identifier  "Card0"
    Driver      "fbdev"
EndSection

Section "Screen"
    Identifier "Screen0"
    Device     "Card0"
    Monitor    "Monitor0"
EndSection

Section "ServerFlags"
    Option "DontVTSwitch" "true"
    Option "AllowMouseOpenFail" "true"
    Option "PciForceNone" "true"
    Option "AutoAddDevices" "false"
EndSection
EOL
fi

# Configure XRDP with strict display settings
echo "Configuring XRDP..."

# Create XRDP configuration directories
mkdir -p /etc/xrdp/conf.d
mkdir -p /etc/X11/xrdp

# Configure XRDP main settings
cat > /etc/xrdp/xrdp.ini << EOL
[Globals]
ini_version=1
port=1431
enable_token_verification=true
max_bpp=32
fork=true
tcp_nodelay=true
tcp_keepalive=true
security_layer=negotiate
crypt_level=high
allow_channels=true
max_idle_time=0
channel_code=1
xorg_path=/usr/lib/xorg
autorun=/etc/xrdp/startwm.sh
display_num=10
required_keylayout=us

[Xorg]
name=Xorg
lib=libxup.so
username=ask
password=ask
ip=127.0.0.1
port=-1
code=20
chansrvport=DISPLAY(10)
xserverbpp=24
EOL

# Configure Xorg specifically for XRDP
cat > /etc/X11/xrdp/xorg.conf << EOL
Section "ServerLayout"
    Identifier     "XRDP Layout"
    Screen      0  "XRDP Screen" 0 0
    InputDevice    "XRDP Mouse" "CorePointer"
    InputDevice    "XRDP Keyboard" "CoreKeyboard"
    Option         "Xinerama" "off"
EndSection

Section "InputDevice"
    Identifier  "XRDP Keyboard"
    Driver      "kbd"
    Option      "XkbLayout" "us"
    Option      "XkbModel" "pc105"
EndSection

Section "InputDevice"
    Identifier  "XRDP Mouse"
    Driver      "mouse"
    Option      "CorePointer" "true"
EndSection

Section "Monitor"
    Identifier  "XRDP Monitor"
    Option      "DPMS" "true"
EndSection

Section "Device"
    Identifier  "XRDP Card"
    Driver      "dummy"
    Option      "ConstantDPI" "true"
    VideoRam    256000
EndSection

Section "Screen"
    Identifier "XRDP Screen"
    Device     "XRDP Card"
    Monitor    "XRDP Monitor"
    DefaultDepth     24
    
    SubSection "Display"
        Depth     24
        Modes     "1920x1080" "1600x900" "1280x1024"
        Virtual   1920 1080
    EndSubSection
EndSection

Section "ServerFlags"
    Option "DontVTSwitch" "true"
    Option "DisableVTSwitch" "true"
    Option "AutoAddDevices" "false"
    Option "DontZoom" "true"
    Option "DontZap" "true"
EndSection

Section "Extensions"
    Option "COMPOSITE" "Disable"
EndSection
EOL

# Create XRDP session startup script with fixed display
cat > /etc/xrdp/startwm.sh << EOL
#!/bin/bash
# Start XRDP session with fixed display
export DISPLAY=:10
export XAUTHORITY=\$HOME/.Xauthority

# Ensure clean X authority
rm -f \$XAUTHORITY
touch \$XAUTHORITY
xauth generate :10 . trusted

# Set up session environment
export XDG_SESSION_TYPE=x11
export DESKTOP_SESSION=xfce
export GDMSESSION=xfce
export XDG_CURRENT_DESKTOP=XFCE
export XDG_CONFIG_DIRS=/etc/xdg/xdg-xfce:/etc/xdg
export XDG_DATA_DIRS=/usr/share/xfce4:/usr/share/xfce:/usr/local/share:/usr/share
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export LANG=en_US.UTF-8

# Start XFCE session
exec dbus-launch --exit-with-session startxfce4
EOL
chmod +x /etc/xrdp/startwm.sh

# Create X server lock directory with proper permissions

# Create display lock directory
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# Restart XRDP service
echo "Restarting XRDP service..."
systemctl restart xrdp

# Ensure XRDP starts after LightDM
if [ -f /etc/init.d/lightdm ]; then
    systemctl add-wants graphical.target xrdp.service
    systemctl set-property xrdp.service After=lightdm.service
fi

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
