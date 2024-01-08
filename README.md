# Homelab
![License](https://img.shields.io/github/license/MarcOrfilaCarreras/homelab?style=flat) ![GitHub last commit](https://img.shields.io/github/last-commit/MarcOrfilaCarreras/homelab?style=flat)

## :information_source: Overview

Welcome to my personal homelab setup! This repository houses all the Ansible playbooks I use to configure and manage the LXC containers running on my Raspberry Pi 4.

### :books: Tech stack

<table>
    <tr>
        <th>Logo</th>
        <th>Name</th>
    </tr>
    <tr>
        <td><img src="https://raw.githubusercontent.com/walkxcode/Dashboard-Icons/main/png/ansible.png" style="height: 25px"/></td>
        <td>Ansible</td>
    </tr>
    <tr>
        <td><img src="https://raw.githubusercontent.com/walkxcode/Dashboard-Icons/main/png/docker.png" style="height: 25px"/></td>
        <td>Docker</td>
    </tr>
    <tr>
        <td><img src="https://raw.githubusercontent.com/walkxcode/Dashboard-Icons/main/png/github-light.png" style="height: 25px"/></td>
        <td>GitHub</td>
    </tr>
    <tr>
        <td><img src="https://raw.githubusercontent.com/walkxcode/Dashboard-Icons/main/png/proxmox.png" style="height: 25px"/></td>
        <td>Proxmox</td>
    </tr>
    <!-- Start Replace -->
<!-- End Replace -->
</table>

### :memo: Usage

To set up your homelab using the provided Ansible playbooks, follow these steps:

1. **Clone the Repository:**
    ```bash
    git clone https://github.com/MarcOrfilaCarreras/homelab.git
    cd homelab
    ```

2. **Copy Variables File:**
    - Duplicate the `vars.yml.example` file and rename it to `vars.yml`:
        ```bash
        cp vars.yml.example vars.yml
        ```
    - Open the `vars.yml` file in your preferred text editor and fill in the necessary variables with your specific configuration details. This file contains essential settings for your homelab setup.

3. **Run Ansible Playbook:**
    - Execute the Ansible playbook to deploy and configure your homelab:
        ```bash
        ansible-playbook deploy.yml
        ```
    - The playbook will automate the provisioning and configuration of your LXC containers based on the variables you provided in the `vars.yml` file.

### :triangular_ruler: Dependencies
1. **Python**
    - proxmoxer==2.0.1
2. **Ansible**
    - community.general.docker_container
    - community.general.proxmox

### :interrobang: Troubleshooting
> Note:  Always check the official documentation or resources for the specific tools and containers you are using if you encounter issues during setup.

1. **Enabling SSH Server on First Container Creation**

    If this is the first time you're running the playbook and creating containers, you might need to stop the playbook execution to enable the SSH server on the newly created containers. The playbook is designed to automate most of the setup, but due to the nature of container creation, stopping the playbook at this stage might be necessary. Here's how you can do it:
    - When you see the playbook is creating containers, manually interrupt the process (usually by pressing `Ctrl + C`).
    - Follow the instructions provided by your container system to enable SSH on the newly created containers.

2. **Modifying Tailscale Container**
    The Tailscale container might require manual modification after deployment. Follow these steps to configure Tailscale in an unprivileged LXC container:
    - Refer to the official Tailscale documentation for unprivileged LXC containers: [Tailscale LXC Unprivileged Setup](https://tailscale.com/kb/1130/lxc-unprivileged?q=lxc).
    - Follow the provided instructions to make the necessary modifications to your Tailscale container manually.


### :bulb: Diagram

```
                            +------------------+
                            |     Internet     |
                            +--------+---------+
                                     |
                                     |
                            +--------v---------+
                            |      Router      |
                            +--------+---------+
                                     |
                                     |
                            +--------v---------+
                            |      Switch      |
                            +--------+---------+
                                     |
                                     |
                        +------------+------------+
                        |                         |
               +--------v---------+      +--------v---------+
               |   Raspberry Pi   |      |   Other Devices  |
               +--------+---------+      +--------+---------+
                        |
                        |
           +------------+------------+
           |                         |
  +--------v---------+      +--------v---------+
  |      Homelab     |      |     Tailscale    |
  |  (LXC Container) |      |  (LXC Container) |
  +------------------+      +------------------+
```

## :key: License

Distributed under the MIT License. See `LICENSE.md` file for more information.