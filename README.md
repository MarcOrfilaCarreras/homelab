# Homelab

![License](https://img.shields.io/github/license/MarcOrfilaCarreras/homelab?style=flat) ![GitHub last commit](https://img.shields.io/github/last-commit/MarcOrfilaCarreras/homelab?style=flat)

## 🧰 Overview

Welcome to my personal Homelab setup!

This repository contains the scripts I use to configure and manage my Raspberry Pi 4 and Raspberry Pi Zero 2 devices.

It provides a simple `Makefile`-based deployment system to copy scripts to your remote servers.

## 📦 Getting Started

1. Clone the Repository:
```bash
git clone https://github.com/MarcOrfilaCarreras/homelab.git
```

2. Navigate to `homelab`:
```bash
cd homelab
```

3. Copy the scripts to your servers:
```bash
make copy
```

After copying, SSH into your device manually and run the appropriate scripts:

``` bash
ssh admin@rpi-zero.local

cd /root/homelab
./devices/rpi-zero.sh     # Example: device-specific script
./common/basic/update.sh     # Example: shared script
```

> 📝 You are responsible for running the correct script(s) for your specific device or use case.

## ⚙️ Configuration
Before running any commands, you must edit the Makefile to define your environment:

```makefile
DEVICES     = rpi-zero.local          # List of hostnames or IPs
USERS       = admin                   # Corresponding usernames
SSH_KEYS    = $(HOME)/.ssh/homelab    # Path(s) to your SSH private key(s)
SSH_PORTS   = 22 717                  # Ports to try for each device
```

> 🔐 Important: The script will first try connecting using the SSH keys on each port. If all key-based attempts fail, it will fall back to password authentication (you will be prompted).

## License

See the [LICENSE.md](LICENSE.md) file for details.