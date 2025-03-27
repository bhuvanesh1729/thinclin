# ThinClin - Remote Access Solution for Ubuntu

ThinClin is an automated remote access solution for Ubuntu machines that sets up XRDP with XFCE4 desktop environment and provides secure remote access through LocalTunnel. It's designed to be easy to install and use, allowing remote desktop access from any device without complex network configuration.

## Features

- 🚀 One-command installation
- 🖥️ XFCE4 desktop environment
- 🌐 Automatic tunnel creation for remote access
- 🔒 Secure connection handling
- 🛠️ Automatic service configuration
- 📝 Detailed logging
- 🔄 Auto-restart capability

## Prerequisites

- Ubuntu Linux (16.04 or later)
- Root/sudo access
- Internet connection

## Quick Start

```bash
curl -sSL https://raw.githubusercontent.com/bhuvanesh1729/thinclin/main/install_thinclin.sh | sudo bash
```

For detailed installation instructions and connection guides, see [DEPLOYMENT.md](DEPLOYMENT.md).

## How It Works

1. **Installation**: The script installs and configures:
   - XRDP (Remote Desktop Protocol server)
   - XFCE4 (Desktop Environment)
   - LocalTunnel (for remote access)
   - Required system services

2. **Configuration**:
   - Sets up XRDP to use port 1431
   - Configures XFCE4 as the desktop environment
   - Creates and starts LocalTunnel service
   - Sets up proper firewall rules

3. **Access**:
   - Generates a unique LocalTunnel URL
   - Allows RDP connections through this URL
   - Supports Windows, macOS, and Linux clients

## System Requirements

- **CPU**: 1+ cores
- **RAM**: 2GB minimum (4GB recommended)
- **Storage**: 2GB free space
- **Network**: Stable internet connection

## Troubleshooting

1. **Check service status**:
```bash
systemctl status xrdp
systemctl status thinclin-tunnel
```

2. **View LocalTunnel URL**:
```bash
journalctl -u thinclin-tunnel.service | grep "your url is"
```

3. **Check logs**:
```bash
journalctl -u xrdp
journalctl -u thinclin-tunnel
```

## Security Considerations

- Change default user password
- Keep system updated
- Monitor access logs
- Configure firewall rules
- Use strong authentication
- Consider SSL setup for additional security

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - feel free to use in your own projects.

## Support

For issues and feature requests, please [open an issue](https://github.com/bhuvanesh1729/thinclin/issues) on GitHub.
