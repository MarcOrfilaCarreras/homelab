# Homelab
![License](https://img.shields.io/github/license/MarcOrfilaCarreras/homelab?style=flat) ![GitHub last commit](https://img.shields.io/github/last-commit/MarcOrfilaCarreras/homelab?style=flat)

## :information_source: Overview

Welcome to my personal homelab setup! This repository houses all the Ansible playbooks I use to configure and manage my Raspberry Pi 4.

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
    <!-- Start Replace -->
    <tr><td><img src="https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/duplicati.png" style="height: 25px"></img></td><td>Duplicati</td></tr> 
    <tr><td><img src="https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/transmission.png" style="height: 25px"></img></td><td>Transmission</td></tr> 
    <tr><td><img src="https://static.vecteezy.com/system/resources/previews/019/617/157/original/container-isometric-symbol-png.png" style="height: 25px"></img></td><td>Pihole</td></tr> 
    <tr><td><img src="https://static.vecteezy.com/system/resources/previews/019/617/157/original/container-isometric-symbol-png.png" style="height: 25px"></img></td><td>Twitch-channel-points-miner-v2</td></tr> 
    <tr><td><img src="https://static.vecteezy.com/system/resources/previews/019/617/157/original/container-isometric-symbol-png.png" style="height: 25px"></img></td><td>Amule</td></tr> 
    <tr><td><img src="https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/watcharr.png" style="height: 25px"></img></td><td>Watcharr</td></tr> 
    <tr><td><img src="https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/vikunja.png" style="height: 25px"></img></td><td>Vikunja</td></tr> 
    <tr><td><img src="https://static.vecteezy.com/system/resources/previews/019/617/157/original/container-isometric-symbol-png.png" style="height: 25px"></img></td><td>Registry</td></tr> 
    <tr><td><img src="https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/watchtower.png" style="height: 25px"></img></td><td>Watchtower</td></tr> 
    <tr><td><img src="https://static.vecteezy.com/system/resources/previews/019/617/157/original/container-isometric-symbol-png.png" style="height: 25px"></img></td><td>Goatcounter</td></tr> 
    <tr><td><img src="https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/flame.png" style="height: 25px"></img></td><td>Flame</td></tr> 
    <tr><td><img src="https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/filebrowser.png" style="height: 25px"></img></td><td>Filebrowser</td></tr> 
    <tr><td><img src="https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/jellyfin.png" style="height: 25px"></img></td><td>Jellyfin</td></tr> 
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

3. **Copy Servers File:**
    - Duplicate the `servers.example` file and rename it to `servers`:
        ```bash
        cp servers.example servers
        ```
    - Open the `servers` file in your preferred text editor and fill in the necessary variables with your specific configuration details. This file contains essential settings for your homelab setup.

4. **Run Ansible Playbook:**
    - Execute the Ansible playbook to deploy and configure your homelab:
        ```bash
        ansible-playbook -i servers deploy.yml
        ```
    - The playbook will automate the provisioning and configuration of your homelab based on the variables you provided in the `vars.yml` file.

### :triangular_ruler: Dependencies
1. **Ansible**
    - community.general.docker_container

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
```

## :key: License

Distributed under the MIT License. See `LICENSE.md` file for more information.