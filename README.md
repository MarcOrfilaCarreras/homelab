<div>

# 🖥️ Homelab

![License](https://img.shields.io/github/license/MarcOrfilaCarreras/homelab?style=flat) ![GitHub last commit](https://img.shields.io/github/last-commit/MarcOrfilaCarreras/homelab?style=flat)

</div>

## 💡 Overview

This repository documents and manages my complete personal homelab setup. It's built around a collection of **modular Bash scripts** designed for:

* **Security Hardening:** Implementing best practices to secure Linux servers (e.g., firewall configuration, SSH hardening).
* **System Configuration:** Automating initial setup tasks on fresh Debian, Ubuntu, and Raspberry Pi OS installations.
* **Service Deployment:** (e.g., Docker).

## 🚀 Getting Started

The configuration is deployed via a single, automated setup script that orchestrates the entire process.

Use the command below to fetch and execute the entire configuration script. This requires `curl` or `wget` and **must be run as root**.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/MarcOrfilaCarreras/homelab/master/install.sh)"
```

### 🧪 Testing

It is highly recommended to test the scripts in a throwaway container before deploying on physical hardware. This example uses a Debian container:

```bash
# 1. Start a privileged container and mount the local repository
docker run -d --name homelab-debian-test --volume "$(pwd)":/tmp/repository --privileged -it debian:trixie-slim

# 2. Access the container's shell
docker exec -it homelab-debian-test /bin/bash

# 3. Inside the container, you can now execute /tmp/repository/install.sh
/tmp/repository/install.sh
```

## 📚 Resources & Documentation

- [Bash Shell documentation](https://www.gnu.org/software/bash/manual/) - Essential for understanding the scripts.
- [Debian Administrator's Handbook](https://debian-handbook.info/) - Reference for system hardening and configuration.

## 🔑 License

Distributed under the MIT License. See `LICENSE.md` file for more information.
