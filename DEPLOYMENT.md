# ThinClin Deployment Guide

## Quick Installation

To install ThinClin on your Ubuntu machine, run this one-liner:

```bash
curl -sSL https://raw.githubusercontent.com/bhuvanesh1729/thinclin/main/install_thinclin.sh | sudo bash
```

## Post-Installation

1. The script will automatically:
   - Install and configure XRDP with XFCE4
   - Set up LocalTunnel for remote access
   - Configure the firewall
   - Start the required services

2. After installation, you'll see:
   - Your local IP and port (1431)
   - A LocalTunnel URL for remote access

3. To check the LocalTunnel URL at any time:
```bash
journalctl -u thinclin-tunnel.service | grep "your url is"
```

## Connecting to Your ThinClin Instance

### Windows
1. Open Remote Desktop Connection (mstsc.exe)
2. Enter the LocalTunnel URL (without https://) as the computer name
3. Click Connect
4. Enter your Ubuntu username and password

### macOS
1. Install Microsoft Remote Desktop from the App Store
2. Click 'Add PC'
3. Enter the LocalTunnel URL (without https://) as the PC name
4. Click Add
5. Double-click the connection and enter your Ubuntu credentials

### Linux
1. Install Remmina or another RDP client:
   ```bash
   sudo apt-get install remmina remmina-plugin-rdp
   ```
2. Open Remmina
3. Create a new connection profile
4. Set protocol to RDP
5. Enter the LocalTunnel URL (without https://) as the server
6. Enter your Ubuntu credentials
7. Connect

## Security Notes
- Change the default user password immediately
- Keep your system updated
- Monitor access logs regularly
- Consider setting up SSL for additional security
