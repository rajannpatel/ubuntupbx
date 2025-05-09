# Install FreePBX 17 on Ubuntu 24.04 LTS

- with open-source dependencies (including Asterisk) installed from Ubuntu's official repositories
- using this [cloud-init.yaml](./cloud-init.yaml) installation template
- on machines where Ubuntu is already installed, or on public cloud virtual machines

<details>

<summary>&ensp;TABLE OF CONTENTS<br><sup>&emsp;&ensp;&thinsp;&thinsp;CLICK TO EXPAND</sup><br></summary>

<a name="server-1-icon"><img align="right" alt="machine" width="50" src="./images/icons8-server-100.png" /></a>

- **[OPTION 1](#install-freepbx-and-asterisk-on-an-existing-ubuntu-machine-icon)**<br><sub>INSTALL FREEPBX AND ASTERISK ON AN UBUNTU MACHINE</sub><br>

  > <sub>[STEP 1](#step-1-icon)<br>DOWNLOAD AND EDIT JINJA VARIABLES IN THE CLOUD-INIT FILE FROM THIS REPOSITORY</sub><br>

  > <sub>[STEP 2](#step-2-icon)<br>USE J2CLI TO INTERPRET JINJA VARIABLES AND RENDER YAML OUTPUT</sub><br>

  > <sub>[STEP 3](#step-3-icon)<br>INSTALL FREEPBX USING THE CLOUD-INIT.YAML FILE</sub><br>

<a name="cloud-1-icon"><img align="right" alt="cloud" width="50" src="./images/icons8-cloud-100.png" /></a>

- **[OPTION 2](#install-freepbx-and-asterisk-on-ubuntu-in-google-cloud-icon)**<br><sub>INSTALL FREEPBX AND ASTERISK ON UBUNTU IN GOOGLE CLOUD</sub><br>

  > <sub>[STEP 1](#step-1-1-icon)<br>MAKE A CLOUD-DEPLOYMENT WORKSPACE FOR GOOGLE CLOUD COMMAND LINE INTERFACE (GCLOUD CLI)</sub><br>

  > <sub>[STEP 2](#step-2-1-icon)<br>INSTALL AND CONFIGURE GCLOUD CLI IN THE CLOUD-DEPLOYMENT WORKSPACE</sub><br>

  > <sub>[STEP 3](#step-3-1-icon)<br>USE GCLOUD CLI TO PROVISION A FREE UBUNTU VM WITH CLOUD-INIT, AND CONFIGURE THE FIREWALL</sub><br>

  > <sub>[HOW DO I UNDO?](#how-do-i-undo-icon)<br>HOW TO DELETE THINGS IN GOOGLE CLOUD</sub><br>

</details>

---

<a name="install-freepbx-and-asterisk-on-an-existing-ubuntu-machine-icon"></a>

<a name="install-freepbx-and-asterisk-on-an-existing-ubuntu-machine-icon-png"><img alt="VoIP" width="50" src="./images/icons8-office-phone-100.png" /><img alt="FoIP" width="50" src="./images/icons8-fax-100.png" /><img alt="on" width="50" src="./images/icons8-right-50.png" /><img alt="Ubuntu Server" width="50" src="./images/icons8-server-100.png" /></a>

## Install FreePBX and Asterisk on an existing Ubuntu machine

> [!IMPORTANT]
> <a name="info-bubble-1"><img align="right" alt="Info Bubble" width="50" src="./images/icons8-info-100.png" /></a>
> #### Securely run FreePBX on Ubuntu 24.04 LTS until 2036
> Asterisk, NodeJS, and other FreePBX dependencies are security maintained by Canonical on Ubuntu.
> - Ubuntu Pro includes security patching for all open source software on Ubuntu for 10 years, until 2034
> - Ubuntu Pro Legacy adds 2 more years of security coverage until 2036
> - Ubuntu Pro is FREE for personal use or commercial evaluation on 5 machines
> 
> <sub>NEXT</sub><p>Get your free or paid [Ubuntu Pro token](https://ubuntu.com/pro/dashboard)</p>

| <a name="steps-1"><img alt="Steps" width="50" src="./images/icons8-steps-100.png" /></a> | 3&nbsp;Steps |
|:---|:---|
| **[STEP&nbsp;1](#step-1-icon)** | Download and edit Jinja variables in the cloud-init file from this repository |
| **[STEP&nbsp;2](#step-2-icon)** | Use **j2cli** to interpret Jinja variables and render YAML output |
| **[STEP&nbsp;3](#step-3-icon)** | Install FreePBX using the cloud-init.yaml file |

<br><sub>PROGRESS &emsp;&emsp; :heavy_plus_sign: &emsp; <a href="#step-1-icon">STEP 1</a>&emsp;&emsp; :heavy_multiplication_x: &emsp; STEP 2&emsp;&emsp; :heavy_multiplication_x: &emsp;STEP 3</sub><br><br>

---

<a name="step-1-icon"></a>

<a name="step-1-icon-png"><img alt="Download and Edit" width="50" src="./images/icons8-edit-file-100.png" /></a>

### STEP 1
Download the cloud-init file from this repository

```bash
curl -L -o cloud-init-jinja.yaml https://raw.githubusercontent.com/rajannpatel/ubuntupbx/refs/heads/main/cloud-init.yaml
nano cloud-init-jinja.yaml
```

<details>

<summary>&ensp;Edit cloud-init-jinja.yaml and configure Jinja variables between lines 4 and 74.<br><sup>&emsp;&ensp;&thinsp;&thinsp;CLICK TO EXPAND</sup><br></summary>

```markdown
# SET OUR VARIABLES
# =================

# Ubuntu Pro token from: https://ubuntu.com/pro/dashboard (not needed for Ubuntu Pro instances on Azure, AWS, or Google Cloud)
{% set TOKEN = '' %}

# SMTP credentials (sendgrid and gmail example configurations)
# sendgrid: https://console.cloud.google.com/marketplace/product/sendgrid-app/sendgrid-email
# {% set SMTP_HOST = 'smtp.sendgrid.net' %}
# {% set SMTP_PORT = '587' %}
# {% set SMTP_USERNAME = 'apikey' %}
# substitute `YOUR-API-KEY-HERE` below, with your API KEY, https://app.sendgrid.com/settings/api_keys
# {% set SMTP_PASSWORD = 'YOUR-API-KEY-HERE' %}

# gmail:
# {% set SMTP_HOST = 'smtp.gmail.com' %}
# {% set SMTP_PORT = '587' %}
# replace `YOUREMAIL@GMAIL.COM` with your email, get `YOUR-APP-PASSWORD` from: https://myaccount.google.com/apppasswords
# {% set SMTP_USERNAME = 'YOUREMAIL@GMAIL.COM' %}
# {% set SMTP_PASSWORD = 'YOUR-APP-PASSWORD' %}

{% set SMTP_HOST = '' %}
{% set SMTP_PORT = '' %}
{% set SMTP_USERNAME = '' %}
{% set SMTP_PASSWORD = '' %}

# NOTIFICATION_EMAIL address for daily crontab notifications
{% set NOTIFICATION_EMAIL = 'youremail@example.com' %}

# HOSTNAME and FQDN are used by Postfix, and necessary for Sendgrid
# HOSTNAME: subdomain of FQDN (e.g. `server` for `server.example.com`)
# FQDN (e.g. `example.com` or `server.example.com`)
{% set HOSTNAME = 'voip' %}
{% set FQDN = 'voip.example.com' %}

# OPTIONAL: PRECONFIGURE FREEPBX CORE MODULE (OUTBOUND ROUTES AND TRUNKS)
# ubuntupbx.core.backup.tar.gz was generated with the Backup & Restore FreePBX Module
# this can be replaced with the https:// or gs:// address of your backup file, if you're copying configurations from another FreePBX installation
{% set RESTORE_BACKUP = 'https://github.com/rajannpatel/ubuntupbx/raw/refs/heads/main/ubuntupbx.core.backup.tar.gz' %}
# ubuntupbx.core.backup.tar.gz Outbound Routes include: N11, North America FoIP, North America VoIP, International VoIP
# ubuntupbx.core.backup.tar.gz SIP Trunks include:
{% set enable_T38Fax = true %}      # https://t38fax.com
{% set enable_Flowroute = false %}  # https://flowroute.com
{% set enable_Telnyx = false %}     # https://telnyx.com
{% set enable_BulkVS = true %}      # https://bulkvs.com

# List of public IPv4 addresses that should never be blocked by fail2ban
# - Use standard dotted decimal notation for each IP address or CIDR (slash) notation IP ranges
# - Separate multiple entries with a space, and do not use commas:
# {% set USER_IPS = '192.178.0.0/15 142.251.47.238' %}
{% set USER_IPS = '' %}

# TIMEZONE: default value is fine
# As represented in /usr/share/zoneinfo. An empty string ('') will result in UTC time being used.
{% set TIMEZONE = 'America/New_York' %}

# TIME TO INSTALL AND REBOOT UBUNTU FOR SECURITY PATCHES FROM CANONICAL IN XX:XX FORMAT
{% set SECURITY_INSTALL_TIME = "04:10" %}
{% set SECURITY_REBOOT_TIME = "04:30" %}

# NUMBER OF DAYS TO RETAIN CDR AND CEL RECORDS IN FREEPBX
{% set CDR_RETENTION_DAYS = "60" %}
{% set CEL_RETENTION_DAYS = "60" %}

# PHP 8.2 IS OFFICIALLY TESTED WITH FREEPBX BY SANGOMA, PHP 8.2 IS SECURITY MAINTAINED UNTIL 31 Dec 2026 FROM THE PHP GROUP (UPSTREAM)
# PHP 8.3 IS COMPATIBLE WITH FREEPBX AND ALL AVAILABLE MODULES, PHP 8.3 GETS SECURITY PATCHING UNTIL 2036 THROUGH CANONICAL, THE PUBLISHERS OF UBUNTU
# PHP_VERSION = 8.2|8.3
{% set PHP_VERSION = "8.2" %}

# =========================
# END OF SETTING VARIABLES
```

</details>

<sub>PROGRESS &emsp;&emsp; :heavy_check_mark: &emsp;STEP 1&emsp;&emsp; :heavy_plus_sign: &emsp; <a href="#step-2-icon">STEP 2</a>&emsp;&emsp; :heavy_multiplication_x: &emsp;STEP 3</sub><br><br>

---

<a name="step-2-icon"></a>

<a name="step-2-icon-png"><img alt="Export to YAML" width="50" src="./images/icons8-export-100.png" /></a>

### STEP 2
Use **j2cli** to interpret Jinja variables and render YAML output

```bash
sudo apt update
sudo apt install j2cli
j2 cloud-init-jinja.yaml > cloud-init.yaml
```

<sub>PROGRESS &emsp;&emsp; :heavy_check_mark: &emsp;STEP 1&emsp;&emsp; :heavy_check_mark: &emsp; STEP 2&emsp;&emsp; :heavy_plus_sign: &emsp; <a href="#step-3-icon">STEP 3</a></sub><br><br>

---

<a name="step-3-icon"></a>

<a name="step-3-icon-png"><img alt="Apply cloud-init" width="50" src="./images/icons8-cloud-file-100.png" /></a>

### STEP 3
Install FreePBX using the cloud-init.yaml file, and configure firewall automations

1. Install FreePBX

    ```bash
    # comment shows estimated time to completion, for each command
    sudo cloud-init single --frequency always --name ubuntu_pro --file cloud-init.yaml # 7m32s 
    sudo cloud-init single --frequency always --name timezone --file cloud-init.yaml # 1s 
    sudo cloud-init single --frequency always --name set_hostname --file cloud-init.yaml # 1s
    sudo cloud-init single --frequency always --name update_hostname --file cloud-init.yaml # 1s
    sudo cloud-init single --frequency always --name users_groups --file cloud-init.yaml # 1s
    sudo cloud-init single --frequency always --name write_files --file cloud-init.yaml # 1s
    sudo cloud-init single --frequency always --name apt_configure --file cloud-init.yaml # 14s
    sudo cloud-init single --frequency always --name package-update-upgrade-install --file cloud-init.yaml # 17m
    sudo cloud-init single --frequency always --name runcmd --file cloud-init.yaml # 1s
    sudo cloud-init single --frequency always --name scripts_user # 20m15s
    ```

2. Print the FreePBX web portal address and configure Asterisk via a web browser:

    ```bash
    echo "http://$(ip route get 1 | awk '{print $7; exit}')"
    ```

    Connect to the Asterisk CLI, and observe output as you configure and use FreePBX:

    ```bash
    sudo su -s /bin/bash asterisk -c 'cd ~/ && asterisk -rvvvvv'
    ```

    -  The `exit` command will safely exit the Asterisk CLI.

3. fail2ban blocks IPs after 3 invalid authentication attempts on SSH, Asterisk, and FreePBX. fail2ban also emails alerts when the dynamic firewall turns on, turns off, and when an IP is banned due to invalid authentication attempts on Asterisk and FreePBX.

    <details>

    <summary>&ensp;Manage the fail2ban dynamic firewall<br><sup>&emsp;&ensp;&thinsp;&thinsp;CLICK TO EXPAND</sup><br></summary>

    ##### Append more user and provider IPs to `ignoreip =` in jail.local
    
    - any additional public IPv4 addresses which should never be banned are listed in the `IP` variable
    - Use standard dotted decimal notation for each IP address or CIDR (slash) notation IP ranges
    - Separate multiple entries with a space, and do not use commas.<br><sub>&ensp;EXAMPLE<br>&ensp;`IP='192.178.0.0/15 142.251.47.238'`</sub><br><br>

    ```bash
    IP=''
    sudo sed -i "s/ignoreip = \(.*\)/ignoreip = \1 $IP/" /etc/fail2ban/jail.local
    sudo fail2ban-client reload
    ```

    ##### Confirm the ignoreip list is accurate

    Invalid IPs in the ignoreip setting in /etc/fail2ban/jail.local will result in 0.0.0.0 (whole world) being ignored.

    ```bash
    sudo fail2ban-client get asterisk ignoreip
    ```

    ##### List all banned IPs in fail2ban jails

    ```bash
    sudo sh -c "fail2ban-client status | sed -n 's/,//g;s/.*Jail list://p' | xargs -n1 fail2ban-client status"
    ```

    ##### Monitor IPs fail2ban is evaluating, in realtime

    ```bash
    tail -f /var/log/fail2ban.log
    ```

    ##### Unban IP from fail2ban jails

    - Replace `127.0.0.1` with the IP address that needs to be unbanned
    - The 3 jails are named **sshd**, **asterisk**, and **freepbx**
    - A `1` output indicates successful removal, a `0` output indicates the IP was not banned<br><br>

    ```bash
    $IP='127.0.0.1'
    sudo fail2ban-client unban sshd $IP
    sudo fail2ban-client unban asterisk $IP
    sudo fail2ban-client unban freepbx $IP
    ```

    </details>


<sub>PROGRESS &emsp;&emsp; :heavy_check_mark: &emsp;STEP 1&emsp;&emsp; :heavy_check_mark: &emsp; STEP 2&emsp;&emsp; :heavy_check_mark: &emsp;STEP 3&emsp;&emsp; :tada: &emsp;COMPLETED</sub><br><br>

---

<a name="install-freepbx-and-asterisk-on-ubuntu-in-google-cloud-icon"></a>

<a name="install-freepbx-and-asterisk-on-ubuntu-in-google-cloud-icon-png"><img alt="VoIP" width="50" src="./images/icons8-office-phone-100.png" /><img alt="FoIP" width="50" src="./images/icons8-fax-100.png" /><img alt="via" width="50" src="./images/icons8-right-50.png" /><img alt="Cloud" width="50" src="./images/icons8-cloud-100.png" />

## Install FreePBX and Asterisk on Ubuntu in Google Cloud

> [!TIP]
> <a name="info-lightbulb-icon-1"><img align="right" alt="Info Lightbulb" width="50" src="./images/icons8-tip-100.png" /></a>
> #### Run FreePBX on a FREE Ubuntu virtual machine on Google Cloud
> - $0 cost to launch
> - $0 recurring expense to run
> 
> <sub>NEXT</sub><p>Install FreePBX and Asterisk on Ubuntu in Google Cloud within the [always free](https://cloud.google.com/free/docs/free-cloud-features#compute) limits</p>

| <a name="steps-icon-2"><img alt="Steps" width="50" src="./images/icons8-steps-100.png" /></a> | 3&nbsp;Steps |
|:---|:---|
| **[STEP&nbsp;1](#step-1-1-icon)** | Make a cloud-deployment workspace for Google Cloud Command Line Interface (gcloud CLI) |
| **[STEP&nbsp;2](#step-2-1-icon)** | Install and configure gcloud CLI in the cloud-deployment workspace |
| **[STEP&nbsp;3](#step-3-1-icon)** | Use gcloud CLI to provision a free Ubuntu VM with cloud-init, and configure the firewall |

<br><sub>PROGRESS &emsp;&emsp; :heavy_plus_sign: &emsp; <a href="#step-1-1-icon">STEP 1</a>&emsp;&emsp; :heavy_multiplication_x: &emsp; STEP 2&emsp;&emsp; :heavy_multiplication_x: &emsp;STEP 3</sub><br><br>

---

<a name="step-1-1-icon"></a>

<a name="step-1-1-icon-png"><img alt="Container or VM" width="50" src="./images/icons8-thin-client-100.png" /></a>

### STEP 1
#### Make a cloud-deployment workspace for gcloud CLI

-  [Multipass](https://multipass.run/) creates Ubuntu VMs on Windows and macOS
-  [LXD](https://canonical.com/lxd/) creates Ubuntu containers on Linux
-  Both Multipass and LXD provide access to an Ubuntu terminal, which is required for Step 2

<a name="pc-icons-1"><img alt="Windows" width="50" src="./images/icons8-windows-client-100.png" /><img alt="macOS" width="50" src="./images/icons8-mac-client-100.png" /></a>

<details>

<summary>&ensp;Set up a cloud-deployment workspace on Windows and macOS<br><sup>&emsp;&ensp;&thinsp;&thinsp;CLICK TO EXPAND</sup><br></summary>

<br>On Windows and macOS, Multipass provides Linux VMs on demand.

1. [Install Multipass](https://multipass.run/install)

2. Launch a VM named "cloud-deployment-workspace":

    ```bash
    multipass launch --name cloud-deployment-workspace
    ```

3. Enter the Multipass VM as the "ubuntu" user:

    ```bash
    multipass shell cloud-deployment-workspace
    ```

</details>

<br><a name="pc-icon-2"><img alt="Linux" width="50" src="./images/icons8-linux-server-100.png" /></a>

<details>

<summary>&ensp;Set up a cloud-deployment workspace on Linux<br><sup>&emsp;&ensp;&thinsp;&thinsp;CLICK TO EXPAND</sup><br></summary>

<br>On Linux, LXD is a system container and VM manager. LXD is built on top of LXC (Linux Containers) but provides a more user-friendly and feature-rich experience. Think of LXD as the tool you use to manage LXC containers, making it easier to create, configure, and run them.

1.  [Install snapd](https://snapcraft.io/docs/installing-snapd) if your Linux doesn't already have it.


2.  [Install LXD](https://canonical.com/lxd/install)

    ```bash
    snap list lxd &> /dev/null && sudo snap refresh lxd --channel latest/stable || sudo snap install lxd --channel latest/stable
    ```

3.  Initialize LXD with default configurations

    ```bash
    lxd init --auto
    ```

4.  Launch a LXD container named "cloud-deployment-workspace" and map your user account on the host machine to the default "ubuntu" user account in the container:

    ```bash
    lxc launch ubuntu:noble cloud-deployment-workspace -c raw.idmap="both 1000 1000"
    ```

5.  Mount your home directory into the container as a disk named "host-home", to conveniently access your files from within the container:

    ```bash
    lxc config device add cloud-deployment-workspace host-home disk source=~/ path=/home/ubuntu
    ```

6.  Enter the LXD container as the "ubuntu" user:

    ```bash
    lxc exec cloud-deployment-workspace -- su -l ubuntu
    ```

</details>

<br><sub>PROGRESS &emsp;&emsp; :heavy_check_mark: &emsp;STEP 1&emsp;&emsp; :heavy_plus_sign: &emsp; <a href="#step-2-1-icon">STEP 2</a>&emsp;&emsp; :heavy_multiplication_x: &emsp;STEP 3</sub><br><br>

---

<a name="step-2-1-icon"></a>

<a name="step-2-1-icon-png"><img alt="Terminal" width="50" src="./images/icons8-terminal-100.png" /></a>

### STEP 2
#### Install and configure gcloud CLI in the cloud-deployment workspace

These steps are performed in your cloud-deployment workspace.

1.  Install gcloud CLI

    ```bash
    sudo snap install google-cloud-cli --classic
    ```

2.  Authenticate with the gcloud CLI

    ```bash
    gcloud init
    ```

    1. Enter **Y** when prompted with *Would you like to log in (Y/n)?*
    2. Visit the authentication link which starts with `https://accounts.google.com/`
    3. Sign in with a Google account
    4. Click **Allow** to grant access to the Google Cloud SDK
    5. Click **Copy** to copy the verification code
    6. Paste the verification code into the terminal window where the `gcloud init` process is running

    Successful authentication within `gcloud init` produces the following output:

    > ```text
    > You are now logged in as [your@email.com].
    > Your current project is [None].  You can change this setting by running:
    > $ gcloud config set project PROJECT_ID
    > ```

<br><sub>PROGRESS &emsp;&emsp; :heavy_check_mark: &emsp;STEP 1&emsp;&emsp; :heavy_check_mark: &emsp; STEP 2&emsp;&emsp; :heavy_plus_sign: &emsp; <a href="#step-3-1-icon">STEP 3</a></sub><br><br>

---

<a name="step-3-1-icon"></a>

<a name="step-3-1-icon-png"><img alt="Cloud" width="50" src="./images/icons8-upload-to-cloud-100.png" /></a>

### STEP 3
#### Use gcloud CLI to provision a free Ubuntu VM with cloud-init, and configure the firewall

These steps are performed in your cloud-deployment workspace.

1. List the projects in the Google Cloud account:
    
    ```bash
    gcloud projects list
    ```
    
    Output will appear in this format:
    
    > ```text
    > PROJECT_ID        NAME              PROJECT_NUMBER
    > project-id        project-name      12345678910
    > ```
    
2. Assign the `PROJECT_ID` environment variable with the Project ID from the `gcloud projects list` output:
    
    ```bash
    PROJECT_ID=project-id
    ```
    
3. Associate gcloud CLI to this `PROJECT_ID`:
    
    ```bash
    gcloud config set project $PROJECT_ID
    ```
    
    This Project ID will contain the "ubuntupbx" VM.
    
4.  Enable the Google Cloud Compute Engine service

    ```bash
    gcloud services enable compute.googleapis.com
    ```

5. List the available cloud zones and cloud regions where VMs can be deployed:

    ```bash
    gcloud compute zones list
    ```

    Output will appear in this format:

    > ```text
    > NAME                       REGION                   STATUS  NEXT_MAINTENANCE  TURNDOWN_DATE
    > us-east1-b                 us-east1                 UP
    > ```

<a name="step-3-6"></a>

6. Google Cloud's free tier is only in the `us-west1`, `us-central1`, and `us-east1` regions

    - Set the `REGION` environment variable with one of the 3 free tier regions
    - Set any `ZONE` in that region from the `gcloud compute zones list` output

    The following zone and region can be used:

    ```bash
    REGION=us-east1
    ZONE=us-east1-b
    ```

7. Reserve a static IP address and label it "pbx-external-ip":
    
    ```bash
    gcloud compute addresses create pbx-external-ip --region=$REGION
    ```
    
8. Download the cloud-init YAML.

    ```bash
    curl -L -O https://raw.githubusercontent.com/rajannpatel/ubuntupbx/refs/heads/main/cloud-init.yaml
    nano cloud-init.yaml
    ```

    <details>

    <summary>&ensp;Edit cloud-init.yaml and configure Jinja variables between lines 4 and 74.<br><sup>&emsp;&ensp;&thinsp;&thinsp;CLICK TO EXPAND</sup><br></summary>

    <br>Set `TOKEN` with a free or paid [Ubuntu Pro token](https://ubuntu.com/pro/dashboard) to enable all security patches, including the [Livepatch](https://ubuntu.com/security/livepatch) security patching automation tool to protect the Linux kernel.

    ```markdown
    # SET OUR VARIABLES
    # =================

    # Ubuntu Pro token from: https://ubuntu.com/pro/dashboard (not needed for Ubuntu Pro instances on Azure, AWS, or Google Cloud)
    {% set TOKEN = '' %}

    # SMTP credentials (sendgrid and gmail example configurations)
    # sendgrid: https://console.cloud.google.com/marketplace/product/sendgrid-app/sendgrid-email
    # {% set SMTP_HOST = 'smtp.sendgrid.net' %}
    # {% set SMTP_PORT = '587' %}
    # {% set SMTP_USERNAME = 'apikey' %}
    # substitute `YOUR-API-KEY-HERE` below, with your API KEY, https://app.sendgrid.com/settings/api_keys
    # {% set SMTP_PASSWORD = 'YOUR-API-KEY-HERE' %}

    # gmail:
    # {% set SMTP_HOST = 'smtp.gmail.com' %}
    # {% set SMTP_PORT = '587' %}
    # replace `YOUREMAIL@GMAIL.COM` with your email, get `YOUR-APP-PASSWORD` from: https://myaccount.google.com/apppasswords
    # {% set SMTP_USERNAME = 'YOUREMAIL@GMAIL.COM' %}
    # {% set SMTP_PASSWORD = 'YOUR-APP-PASSWORD' %}

    {% set SMTP_HOST = '' %}
    {% set SMTP_PORT = '' %}
    {% set SMTP_USERNAME = '' %}
    {% set SMTP_PASSWORD = '' %}

    # NOTIFICATION_EMAIL address for daily crontab notifications
    {% set NOTIFICATION_EMAIL = 'youremail@example.com' %}

    # HOSTNAME and FQDN are used by Postfix, and necessary for Sendgrid
    # HOSTNAME: subdomain of FQDN (e.g. `server` for `server.example.com`)
    # FQDN (e.g. `example.com` or `server.example.com`)
    {% set HOSTNAME = 'voip' %}
    {% set FQDN = 'voip.example.com' %}

    # OPTIONAL: PRECONFIGURE FREEPBX CORE MODULE (OUTBOUND ROUTES AND TRUNKS)
    # ubuntupbx.core.backup.tar.gz was generated with the Backup & Restore FreePBX Module
    # this can be replaced with the https:// or gs:// address of your backup file, if you're copying configurations from another FreePBX installation
    {% set RESTORE_BACKUP = 'https://github.com/rajannpatel/ubuntupbx/raw/refs/heads/main/ubuntupbx.core.backup.tar.gz' %}
    # ubuntupbx.core.backup.tar.gz Outbound Routes include: N11, North America FoIP, North America VoIP, International VoIP
    # ubuntupbx.core.backup.tar.gz SIP Trunks include:
    {% set enable_T38Fax = true %}      # https://t38fax.com
    {% set enable_Flowroute = false %}  # https://flowroute.com
    {% set enable_Telnyx = false %}     # https://telnyx.com
    {% set enable_BulkVS = true %}      # https://bulkvs.com

    # List of public IPv4 addresses that should never be blocked by fail2ban
    # - Use standard dotted decimal notation for each IP address or CIDR (slash) notation IP ranges
    # - Separate multiple entries with a space, and do not use commas:
    # {% set USER_IPS = '192.178.0.0/15 142.251.47.238' %}
    {% set USER_IPS = '' %}

    # TIMEZONE: default value is fine
    # As represented in /usr/share/zoneinfo. An empty string ('') will result in UTC time being used.
    {% set TIMEZONE = 'America/New_York' %}

    # TIME TO INSTALL AND REBOOT UBUNTU FOR SECURITY PATCHES FROM CANONICAL IN XX:XX FORMAT
    {% set SECURITY_INSTALL_TIME = "04:10" %}
    {% set SECURITY_REBOOT_TIME = "04:30" %}

    # NUMBER OF DAYS TO RETAIN CDR AND CEL RECORDS IN FREEPBX
    {% set CDR_RETENTION_DAYS = "60" %}
    {% set CEL_RETENTION_DAYS = "60" %}

    # PHP 8.2 IS OFFICIALLY TESTED WITH FREEPBX BY SANGOMA, PHP 8.2 IS SECURITY MAINTAINED UNTIL 31 Dec 2026 FROM THE PHP GROUP (UPSTREAM)
    # PHP 8.3 IS COMPATIBLE WITH FREEPBX AND ALL AVAILABLE MODULES, PHP 8.3 GETS SECURITY PATCHING UNTIL 2036 THROUGH CANONICAL, THE PUBLISHERS OF UBUNTU
    # PHP_VERSION = 8.2|8.3
    {% set PHP_VERSION = "8.2" %}

    # =========================
    # END OF SETTING VARIABLES
    ```
    
    </details>

9. Create a free-tier e2-micro VM named "ubuntupbx", [other VM types](https://cloud.google.com/compute/docs/machine-resource) cost money.
    
    ```bash
    gcloud compute instances create ubuntupbx \
        --zone=$ZONE \
        --machine-type=e2-micro \
        --address=pbx-external-ip \
        --tags=pbx \
        --service-account=$(gcloud compute project-info describe --format="value(defaultServiceAccount)") \
        --scopes=https://www.googleapis.com/auth/cloud-platform \
        --boot-disk-size=30 \
        --image-family=ubuntu-2404-lts-amd64 \
        --image-project=ubuntu-os-cloud \
        --metadata-from-file=user-data=cloud-init.yaml
    ```

> [!NOTE]
> <a name="info-bubble-2"><img align="right" alt="Info Bubble" width="50" src="./images/icons8-information-100.png" /></a>
> In the steps below, `--source-ranges` can be any number of globally routable IPv4 addresses written as individual IPs, or groups of IPs in slash notation, separated by commas (but no spaces).<br><sub>&ensp;EXAMPLE<br>&ensp;`192.178.0.0/15,142.251.47.238`</sub>
>
> `$(curl -s http://checkip.amazonaws.com)` retrieves the globally routable IPv4 address of the machine where the command is run, using an Amazon AWS service. It appears in some commands below, as a convenience, but can be replaced with manually specified IPs.

> [!TIP]
> <a name="info-lightbulb-2"><img align="right" alt="Info Lightbulb" width="50" src="./images/icons8-tip-100.png" /></a>
> Looking up an individual IP from an ISP at [arin.net](https://arin.net) can reveal the entire CIDR block of possible IPs from that ISP, if wide ranges need to be permitted in the firewall. For example, looking up a Charter Spectrum IP [174.108.85.8](https://search.arin.net/rdap/?query=174.108.85.8) reveals a CIDR of `174.96.0.0/12`. CIDR blocks for popular ISPs serving dynamic IPs to customers in North America appear in the following table:
> | ISP  | CIDR |
> | ------------- | ------------- |
> | [Charter Spectrum Charlotte](https://search.arin.net/rdap/?query=174.96.0.0)  | `174.96.0.0/12`  |
> | [Charter Spectrum Orlando (Road Runner)](https://search.arin.net/rdap/?query=67.8.0.0) | `67.8.0.0/14` |
> | [Optimum Online's Altice Fiber](https://search.arin.net/rdap/?query=174.96.0.0)  | `24.184.0.0/14`  |
> | [Verizon Wireless 5G Home Internet](https://search.arin.net/rdap/?query=75.192.0.0)  | `75.192.0.0/10`  |
> | [Google Fiber](https://search.arin.net/rdap/?query=136.32.0.0)  | `136.32.0.0/11`  |

10. Permit ingress HTTP for management and optionally ICMP for ping replies

    ```bash
    gcloud compute firewall-rules create allow-management-http-icmp \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="$(curl -s http://checkip.amazonaws.com)" \
        --rules="tcp:80,icmp" \
        --description="Access FreePBX via web and ping"
    ```

<a name="step-3-11"></a>

11. Permit ingress UDP traffic for analog telephone adapters (ATAs) and softphones

    ##### This firewall rule allows ingress SIP traffic from your IP

    ```bash
    gcloud compute firewall-rules create allow-devices-sip-rtp-udptl \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="$(curl -s http://checkip.amazonaws.com)" \
        --rules="udp:5060,udp:4000-4999,udp:10000-20000" \
        --description="SIP signaling and RTP & UDPTL media for ATAs and Softphones"
    ```

    ##### This firewall rule allows ingress SIP traffic from the Google Fiber ISP

    - Change the `isp-googlefiber` firewall rule name and `--source-ranges="136.32.0.0/11"` as needed.
    - These allow ingress rules should reflect the ISP and IPv4 ranges of FoIP and VoIP SIP endpoints connecting to "ubuntupbx".
    - Repeat this step for every ISP where SIP endpoints exist.<br><br>

    ```bash
    gcloud compute firewall-rules create isp-googlefiber \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="136.32.0.0/11" \
        --rules="udp:5060,udp:4000-4999,udp:10000-20000" \
        --description="SIP signaling and RTP & UDPTL media for ATAs and Softphones"
    ```

12. Permit ingress traffic from VoIP and/or FoIP SIP Trunk provider(s)

    - allow RTP and UDPTL media streams over Asterisk's configured UDP port ranges
    - allow SIP signaling for inbound calls when using IP authentication<br><br>

    <details>

    <summary>&ensp;T38Fax&ensp;<b>Power-T.38 SIP Trunk for FoIP</b><br><sup>&emsp;&ensp;&thinsp;&thinsp;CLICK TO EXPAND</sup><br></summary>

    <br>[T38Fax](https://t38fax.com) proxies all the RTP and UDPTL packets through their network for observability into the quality of the RTP streams.
    
    ##### RTP and UDPTL ingress rule

    ```bash
    gcloud compute firewall-rules create foip-t38fax-rtp-udptl \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="8.20.91.0/24,130.51.64.0/22,8.34.182.0/24" \
        --rules="udp:4000-4999,udp:10000-20000" \
        --description="T38Fax incoming RTP and UDPTL media streams"
    ```

    ##### SIP signaling ingress rule

    ```bash
    gcloud compute firewall-rules create foip-t38fax-sip \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="8.20.91.0/24,130.51.64.0/22,8.34.182.0/24" \
        --rules="udp:5060" \
        --description="T38Fax SIP Signaling"
    ```

    </details>

    <details>

    <summary>&ensp;Flowroute<br><sup>&emsp;&ensp;&thinsp;&thinsp;CLICK TO EXPAND</sup><br></summary>

    <br>[Flowroute](https://flowroute.com) uses direct media delivery to ensure voice data streams traverse the shortest path between the caller and callee, therefore `--source-ranges="0.0.0.0/0"` allows inbound RTP and UDPTL traffic from anywhere in the world.

    ##### RTP and UDPTL ingress rule

    ```bash
    gcloud compute firewall-rules create voip-flowroute-rtp-udptl \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="0.0.0.0/0" \
        --rules="udp:4000-4999,udp:10000-20000" \
        --description="Flowroute incoming RTP and UDPTL media streams"
    ```

    ##### SIP signaling ingress rule

    ```bash
    gcloud compute firewall-rules create voip-flowroute-sip \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="34.210.91.112/28,34.226.36.32/28,16.163.86.112/30,3.0.5.12/30,3.8.37.20/30,3.71.103.56/30,18.228.70.48/30" \
        --rules="udp:5060" \
        --description="Flowroute SIP Signaling"
    ```

    </details>

    <details>

    <summary>&ensp;Telnyx<br><sup>&emsp;&ensp;&thinsp;&thinsp;CLICK TO EXPAND</sup><br></summary>

    <br>[Telnyx](https://telnyx.com) proxies all the RTP and UDPTL media streams through their network for observability into the quality of the RTP streams.

    ##### RTP and UDPTL ingress rule

    ```bash
    gcloud compute firewall-rules create voip-telnyx-rtp-udptl \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="36.255.198.128/25,50.114.136.128/25,50.114.144.0/21,64.16.226.0/24,64.16.227.0/24,64.16.228.0/24,64.16.229.0/24,64.16.230.0/24,64.16.248.0/24,64.16.249.0/24,103.115.244.128/25,185.246.41.128/25" \
        --rules="udp:4000-4999,udp:10000-20000" \
        --description="Telnyx incoming RTP and UDPTL media streams"
    ```

    ##### SIP signaling ingress rule

    ```bash
    gcloud compute firewall-rules create voip-telnyx-sip \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="192.76.120.10,64.16.250.10,185.246.41.140,185.246.41.141,103.115.244.145,103.115.244.146,192.76.120.31,64.16.250.13" \
        --rules="udp:5060" \
        --description="Telnyx SIP Signaling"
    ```

    </details>

    <details>

    <summary>&ensp;BulkVS<br><sup>&emsp;&ensp;&thinsp;&thinsp;CLICK TO EXPAND</sup><br></summary>

    <br>[BulkVS](https://bulkvs.com) proxies all the RTP and UDPTL packets through their network for observability into the quality of the RTP streams.

    ##### RTP and UDPTL ingress rule

    ```bash
    gcloud compute firewall-rules create voip-bulkvs-rtp-udptl \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="162.249.171.198,23.190.16.198,76.8.29.198" \
        --rules="udp:4000-4999,udp:10000-20000" \
        --description="BulkVS incoming RTP and UDPTL media streams"
    ```

    ##### SIP signaling ingress rule

    ```bash
    gcloud compute firewall-rules create voip-bulkvs-sip \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="162.249.171.198,23.190.16.198,76.8.29.198" \
        --rules="udp:5060" \
        --description="BulkVS SIP Signaling"
    ```

    </details>

13. Observe the installation progress by tailing `/var/log/cloud-init-output.log`
    
    ```bash
    gcloud compute ssh ubuntupbx --zone $ZONE --command "tail -f /var/log/cloud-init-output.log"
    ```
    
14. Authorize gcloud CLI to have SSH access to your Ubuntu virtual machine

    -  First time gcloud CLI users will be prompted for a passphrase twice
    -  This password can be left blank, press <kbd>Enter</kbd> twice to proceed:<br><br>
    
    > ```text
    > WARNING: The private SSH key file for gcloud does not exist.
    > WARNING: The public SSH key file for gcloud does not exist.
    > WARNING: You do not have an SSH key for gcloud.
    > WARNING: SSH keygen will be executed to generate a key.
    > Generating public/private rsa key pair.
    > Enter passphrase (empty for no passphrase):
    > Enter same passphrase again:
    > ```
    
15. This line indicates security patches were applied, and a reboot is required
    
    > ```text
    > 2023-08-20 17:30:04,721 - cc_package_update_upgrade_install.py[WARNING]: Rebooting after upgrade or install per /var/run/reboot-required
    > ```
  
    In the event of a reboot, re-run the tail command to continue observing the progress of the installation; otherwise skip this step:
    
    ```bash
    gcloud compute ssh ubuntupbx --zone $ZONE --command "tail -f /var/log/cloud-init-output.log"
    ```
    
16. When cloud-init prints this `finished at` line, press <kbd>CTRL</kbd> + <kbd>C</kbd> to terminate the tail process.
    
    > ```text
    > Cloud-init v. 24.1.3-0ubuntu3.3 finished at Thu, 20 Jun 2024 03:53:16 +0000. Datasource DataSourceGCELocal.  Up 666.00 seconds
    > ```

17. Access the web portal to set up Trunks and Extensions

    -  These commands will print the web portal links in the terminal
    -  <kbd>CTRL</kbd> click the link to open<br><br>

    ```bash
    dig +short -x $(gcloud compute addresses describe pbx-external-ip --region=$REGION --format='get(address)') | sed 's/\.$//; s/^/http:\/\//'
    ```

    ```bash
    echo "http://$(gcloud compute addresses describe pbx-external-ip --region=$REGION --format='get(address)')"
    ```    

18. Connect to the "ubuntupbx" VM via SSH to configure external backup schedules, and connect to the Asterisk CLI.

    ```bash
    gcloud compute ssh ubuntupbx --zone $ZONE
    ```

    Upon logging in via SSH, edit the "root" user's crontab.

    ```bash
    sudo crontab -e
    ```

    **nano** (option 1) will be the most intuitive option for most users.

    > ```text
    > Select an editor.  To change later, run 'select-editor'.
    > 1. /bin/nano        <---- easiest
    > 2. /usr/bin/vim.basic
    > 3. /usr/bin/vim.tiny
    > 4. /bin/ed
    > ```

    Add the following lines at the bottom of the crontab file. Replace `example-bucket-name` with the name of a Google Cloud Storage bucket in the same project as the virtual machine.

    ```bash
    @daily gcloud storage rsync /var/spool/asterisk/backup gs://example-bucket-name/backup --recursive
    @daily gcloud storage rsync /var/spool/asterisk/monitor gs://example-bucket-name/monitor --recursive
    ```

    -  FreePBX artifacts such as backups and call recordings (if enabled) will be pruned on a schedule through crontab entries for the "root" user.
    -  A Google Cloud Storage S3 Bucket is a suitable location for long term external storage of this data.
    -  Delete stale backups and recordings from the S3 bucket on a schedule with "maximum age" object lifecycle policies.

    Connect to the Asterisk CLI, and observe output as you configure and use FreePBX:

    ```bash
    sudo su -s /bin/bash asterisk -c 'cd ~/ && asterisk -rvvvvv'
    ```

    -  The `exit` command will safely exit the Asterisk CLI.
    -  Running the `exit` command again will quit the SSH session.

19. fail2ban blocks IPs after 3 invalid authentication attempts on SSH, Asterisk, and FreePBX. fail2ban also emails alerts when the dynamic firewall turns on, turns off, and when an IP is banned due to invalid authentication attempts on Asterisk and FreePBX.

    <details>

    <summary>&ensp;Manage the fail2ban dynamic firewall<br><sup>&emsp;&ensp;&thinsp;&thinsp;CLICK TO EXPAND</sup><br></summary>

    ##### Append more user and provider IPs to `ignoreip =` in jail.local
    
    - any additional public IPv4 addresses which should never be banned are listed in the `IP` variable
    - Use standard dotted decimal notation for each IP address or CIDR (slash) notation IP ranges
    - Separate multiple entries with a space, and do not use commas.<br><sub>&ensp;EXAMPLE<br>&ensp;`IP='192.178.0.0/15 142.251.47.238'`</sub><br><br>

    ```bash
    IP=$(curl -s http://checkip.amazonaws.com)
    gcloud compute ssh ubuntupbx --zone $ZONE --command "sudo sed -i 's/ignoreip = \(.*\)/ignoreip = \1 '"$IP"'/' /etc/fail2ban/jail.local"
    gcloud compute ssh ubuntupbx --zone $ZONE --command "sudo fail2ban-client reload"
    ```

    ##### Confirm the ignoreip list is accurate

    Invalid IPs in the ignoreip setting in /etc/fail2ban/jail.local will result in 0.0.0.0 (whole world) being ignored.

    ```bash
    gcloud compute ssh ubuntupbx --zone $ZONE --command "sudo fail2ban-client get asterisk ignoreip"
    ```

    ##### List all banned IPs in fail2ban jails

    ```bash
    gcloud compute ssh ubuntupbx --zone $ZONE --command "sudo fail2ban-client status | sed -n 's/,//g;s/.*Jail list://p' | xargs -n1 sudo fail2ban-client status"
    ```

    ##### Monitor IPs fail2ban is evaluating, in realtime

    ```bash
    gcloud compute ssh ubuntupbx --zone $ZONE --command "tail -f /var/log/fail2ban.log"
    ```

    ##### Unban IP from fail2ban jails

    - Replace `127.0.0.1` with the IP address that needs to be unbanned
    - The 3 jails are named **sshd**, **asterisk**, and **freepbx**
    - A `1` output indicates successful removal, a `0` output indicates the IP was not banned<br><br>

    ```bash
    $IP='127.0.0.1'
    gcloud compute ssh ubuntupbx --zone $ZONE --command "sudo fail2ban-client unban sshd $IP"
    gcloud compute ssh ubuntupbx --zone $ZONE --command "sudo fail2ban-client unban asterisk $IP"
    gcloud compute ssh ubuntupbx --zone $ZONE --command "sudo fail2ban-client unban freepbx $IP"
    ```

    </details>

<sub>PROGRESS &emsp;&emsp; :heavy_check_mark: &emsp;STEP 1&emsp;&emsp; :heavy_check_mark: &emsp; STEP 2&emsp;&emsp; :heavy_check_mark: &emsp;STEP 3&emsp;&emsp; :tada: &emsp;COMPLETED</sub><br><br>

---

<a name="how-do-i-undo-icon"></a>

<a name="how-do-i-undo-icon-png"><img alt="Delete" width="50" src="./images/icons8-delete-100.png" /></a>

### **HOW DO I UNDO?**
#### How to delete things in Google Cloud

> [!WARNING]
> <a name="warning-sign-icon"><img align="right" alt="Warning Sign" width="50" src="./images/icons8-warning-100.png" /></a>
> The following steps are destructive, and will remove everything created by following the above steps, in Google Cloud.

The following steps remove the "ubuntupbx" VM, its static IP address, and its firewall rules.

1. List all VMs in this project:

    ```bash
    gcloud compute instances list
    ```

2. To delete the "ubuntupbx" VM, set `ZONE` to reflect what was specified in [Step 3.6](#step-3-6):

    ```bash
    ZONE=us-east1-b
    gcloud compute instances delete ubuntupbx --zone $ZONE
    ```

3. List all the static addresses:
    
    ```bash
    gcloud compute addresses list
    ```

4. To delete the address named "pbx-external-ip", set `REGION` to reflect what was specified in [Step 3.6](#step-3-6)

    ```bash
    REGION=us-east1
    gcloud compute addresses delete pbx-external-ip --region=$REGION
    ```

5. List all firewall rules in this project:
    
    ```bash
    gcloud compute firewall-rules list
    ```

6. To delete the ingress firewall rules created in [Step 3.11](#step-3-11)

    ```bash
    gcloud compute firewall-rules delete allow-management-http-icmp
    gcloud compute firewall-rules delete allow-devices-sip-rtp-udptl

    gcloud compute firewall-rules delete foip-t38fax-rtp-udptl
    gcloud compute firewall-rules delete foip-t38fax-sip

    gcloud compute firewall-rules delete voip-flowroute-rtp-udptl
    gcloud compute firewall-rules delete voip-flowroute-sip

    gcloud compute firewall-rules delete voip-telnyx-rtp-udptl
    gcloud compute firewall-rules delete voip-telnyx-sip

    gcloud compute firewall-rules delete voip-bulkvs-rtp-udptl
    gcloud compute firewall-rules delete voip-bulkvs-sip
    ```

<br><br><br><br><br><br><br><br>
<a href="https://icons8.com"><img alt="icon credits" align="right" src="./images/icons.png"></a>