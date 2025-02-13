# FreePBX + Asterisk + Ubuntu

<img alt="VoIP" width="50" src="./images/icons8-office-phone-100.png" /><img alt="FoIP" width="50" src="./images/icons8-fax-100.png" /><img alt="via" width="50" src="./images/icons8-right-50.png" /><img alt="Cloud" width="50" src="./images/icons8-cloud-100.png" />

### Install FreePBX 17 on Ubuntu 24.04 LTS, with open-source dependencies installed from Ubuntu's official repositories.

This guide will show you how and where to deploy a long running FreePBX system cost-effectively, reliably, and securely.

> [!TIP]
> Open source software dependencies of FreePBX (including Asterisk) installed from official Ubuntu LTS repositories get 12 years of security patches when free or paid [Ubuntu Pro](https://ubuntu.com/pro) is enabled.

Deploying FreePBX on a single Ubuntu virtual machine (VM) in Google Cloud is an ideal solution for personal users and small to medium-sized businesses. The setup can be scaled up for larger organizations. For disaster recovery, this deployment has daily recovery points with a recovery time measured in minutes, inclusive of all FreePBX, Asterisk, and Ubuntu configurations and customizations.

There is no charge to use Google Cloud's Compute Engine up to their specified [always free](https://cloud.google.com/free/docs/free-cloud-features#compute) usage limit. The free usage limit does not expire, and is perfect for running FreePBX 17 and Asterisk 20.6 on Ubuntu 24.04 LTS.

<hr>

## 3 Steps
### What you will accomplish

<img alt="Steps" width="50" src="./images/icons8-steps-100.png" />

- **[STEP 1](#step-1)** <br>Set up a cloud-deployment workspace, Google Cloud resources like VMs and firewalls can be provisioned and configured from here.
    - Confine the Google Cloud CLI in an Ubuntu VM or container, this VM or container becomes the cloud-deployment workspace.
- **[STEP 2](#step-2)** <br>Install and configure Google Cloud CLI in the cloud-deployment workspace.
    - The Google Cloud CLI is available as a snap package with "classic confinement", meaning it doesn't have strict confinement and has broader system access.
- **[STEP 3](#step-3)** <br>From within the cloud-deployment workspace, launch an Ubuntu VM on Google Cloud that will have:
    - FreePBX 17 and Asterisk 20.6 running on a free Ubuntu 24.04 LTS VM in Google Cloud, with Flowroute, Telnyx, and T38Fax trunks preconfigured for VoIP (voice over IP) and FoIP (fax over IP) using T.38 with T.30 ECM enabled.
    - 12 years of security patching for all open source dependencies of FreePBX, including Asterisk 20.6.
    - security patching automations enabled until the year 2034.

<br><br><sub>PROGRESS: GO TO <a href="#step-1">STEP 1</a></sub><br><br><a href="#step-1"><img alt="Pending Checkbox" width="25" src="./images/icons8-unchecked-radio-button-100.png" /><img alt="Step 1" height="25" src="./images/step1.png" /><img alt="" height="25" src="./images/dash.png" /></a><a href="#step-2"><img alt="" height="25" src="./images/dash.png" /><img alt="Pending Checkbox" width="25" src="./images/icons8-unchecked-radio-button-100.png" /><img alt="Step 2" height="25" src="./images/step2.png" /><img alt="" height="25" src="./images/dash.png" /></a><a href="#step-3"><img alt="" height="25" src="./images/dash.png" /><img alt="Pending Checkbox" width="25" src="./images/icons8-unchecked-radio-button-100.png" /><img alt="Step 3" height="25" src="./images/step3.png" /></a>

<hr>

<img alt="Container or VM" width="50" src="./images/icons8-thin-client-100.png" />

## STEP 1
### Set up a cloud-deployment workspace on Windows, macOS, or Linux

Instead of installing the Google Cloud CLI software directly on your computer, use containers or VMs for process isolation and general organization or your local workspace. Multipass or LXD are available options to create a Linux environment for use as your cloud-deployment workspace.

#### Set up a cloud-deployment workspace on Windows and macOS

<img alt="Windows" width="50" src="./images/icons8-windows-client-100.png" /><img alt="macOS" width="50" src="./images/icons8-mac-client-100.png" />

On Windows and macOS, [Multipass](https://multipass.run/) provides Linux VMs on demand.

1. [Install Multipass](https://multipass.run/install)

2. Launch a VM named "cloud-deployment-workspace":

        multipass launch --name cloud-deployment-workspace

3. Enter the Multipass VM as the **ubuntu** user:

        multipass shell cloud-deployment-workspace

<br><br><sub>PROGRESS: GO TO <a href="#step-2">STEP 2</a></sub><br><br><a href="#step-1"><img alt="Done Checkbox" width="25" src="./images/icons8-checked-radio-button-100.png" /><img alt="Step 1" height="25" src="./images/step1.png" /><img alt="" height="25" src="./images/dash.png" /></a><a href="#step-2"><img alt="" height="25" src="./images/dash.png" /><img alt="Pending Checkbox" width="25" src="./images/icons8-unchecked-radio-button-100.png" /><img alt="Step 2" height="25" src="./images/step2.png" /><img alt="" height="25" src="./images/dash.png" /></a><a href="#step-3"><img alt="" height="25" src="./images/dash.png" /><img alt="Pending Checkbox" width="25" src="./images/icons8-unchecked-radio-button-100.png" /><img alt="Step 3" height="25" src="./images/step3.png" /></a>

#### Set up a cloud-deployment workspace on Linux

<img alt="Linux" width="50" src="./images/icons8-linux-server-100.png" />

On Linux, [LXD](https://canonical.com/lxd/) is a system container and VM manager. LXD is built on top of LXC (Linux Containers) but provides a more user-friendly and feature-rich experience. Think of LXD as the tool you use to manage LXC containers, making it easier to create, configure, and run them.

1.  [Install snapd](https://snapcraft.io/docs/installing-snapd) if your Linux doesn't already have it.


2.  [Install LXD](https://canonical.com/lxd/install) and initialize it

        snap list lxd &> /dev/null && sudo snap refresh lxd --channel latest/stable || sudo snap install lxd --channel latest/stable

3.  Initialize LXD with sensible default, out-of-the-box configurations

        lxd init --auto

4.  Launch a LXD container named **cloud-deployment-workspace** and map your user account on the host machine to the default **ubuntu** user account in the container:

        lxc launch ubuntu:noble cloud-deployment-workspace -c raw.idmap="both 1000 1000"

5.  Optional Step: mount your home directory into the container as a disk named "ubuntupbx-home", to conveniently access your files from within the container:

        lxc config device add cloud-deployment-workspace ubuntupbx-home disk source=~/ path=/home/ubuntu

6.  Enter the LXD container as the **ubuntu** user:

        lxc exec cloud-deployment-workspace -- su -l ubuntu

<br><sup>PROGRESS:</sup><sub>&emsp;&emsp;:heavy_check_mark:&emsp;STEP 1&emsp;&emsp;:heavy_multiplication_x:&emsp;<a href="#step-2">STEP 2</a>&emsp;&emsp;:heavy_multiplication_x:&emsp;STEP 3</sub><br><br>

<hr>

<img alt="Terminal" width="50" src="./images/icons8-terminal-100.png" />

## STEP 2
### Install and configure the gcloud CLI in your cloud-deployment workspace

1.  Install the [gcloud CLI](https://cloud.google.com/sdk/docs/install)

        sudo snap install google-cloud-cli --classic

2.  Authenticate with the gcloud CLI

        gcloud init

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

<sub>PROGRESS</sub><br><br><a href="#step-1"><img alt="Done Checkbox" width="25" src="./images/icons8-checked-radio-button-100.png" /><img alt="Step 1" height="25" src="./images/step1.png" /><img alt="" height="25" src="./images/dash.png" /></a><a href="#step-2"><img alt="" height="25" src="./images/dash.png" /><img alt="Done Checkbox" width="25" src="./images/icons8-checked-radio-button-100.png" /><img alt="Step 2" height="25" src="./images/step2.png" /><img alt="" height="25" src="./images/dash.png" /></a><a href="#step-3"><img alt="" height="25" src="./images/dash.png" /><img alt="Pending Checkbox" width="25" src="./images/icons8-unchecked-radio-button-100.png" /><img alt="Step 3" height="25" src="./images/step3.png" /></a>

<hr>

<img alt="Cloud" width="50" src="./images/icons8-upload-to-cloud-100.png" />

## STEP 3
### Provision resources and deploy an Ubuntu VM on Google Cloud

1. List the projects in the Google Cloud account:
    
       gcloud projects list
    
    Output will appear in this format:
    
    > ```text
    > PROJECT_ID        NAME              PROJECT_NUMBER
    > project-id        project-name      12345678910
    > ```
    
2. Assign the `PROJECT_ID` environment variable with the Project ID from the `gcloud projects list` output:
    
       PROJECT_ID=project-id
    
3. Associate gcloud CLI to this `PROJECT_ID`:
    
       gcloud config set project $PROJECT_ID
    
    This Project ID will contain the PBX VM.
    
4. List the available cloud zones and cloud regions where VMs can be deployed:

       gcloud compute zones list

    Output will appear in this format:

    > ```text
    > NAME                       REGION                   STATUS  NEXT_MAINTENANCE  TURNDOWN_DATE
    > us-east1-b                 us-east1                 UP
    > ```

5. Only regions `us-west1`, `us-central1`, and `us-east1` in North America qualify for Google Cloud's free tier. Set the `ZONE` and `REGION` environment variables with one of the 3 free tier regions, and choose any zone in that region. The following zone and region can be used, or select another zone and region combination from the `gcloud compute zones list` output:

    ```bash
    ZONE=us-east1-b
    REGION=us-east1
    ```

6. Reserve a static IP address and label it "pbx-external-ip":
    
       gcloud compute addresses create pbx-external-ip --region=$REGION
    
7. Use curl to download the cloud-init YAML.

       curl -s https://raw.githubusercontent.com/rajannpatel/ubuntupbx/refs/heads/main/cloud-init.yaml -o cloud-init.yaml

8. Open the file in an editor (like nano) to change configurations specified between lines 4 and 43. Setting `TOKEN` with an [Ubuntu Pro token](https://ubuntu.com/pro/dashboard) is required for security updates to Asterisk, Asterisk's dependencies, and some FreePBX dependencies. [Livepatch](https://ubuntu.com/security/livepatch) will be enabled by this cloud-init.yaml file if a Pro Token is set.

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

    # CRONTAB_EMAIL address for daily crontab notifications
    {% set CRONTAB_EMAIL = 'youremail@example.com' %}

    # HOSTNAME and FQDN are used by Postfix, and necessary for Sendgrid
    # HOSTNAME: subdomain of FQDN (e.g. `server` for `server.example.com`)
    # FQDN (e.g. `example.com` or `server.example.com`)
    {% set HOSTNAME = 'voip' %}
    {% set FQDN = 'voip.example.com' %}

    {% set HUMAN_READABLE_INSTANCE_NAME = "My PBX Server" %}

    # TIMEZONE: default value is fine
    # As represented in /usr/share/zoneinfo. An empty string ('') will result in UTC time being used.
    {% set TIMEZONE = 'America/New_York' %}

    # TIME TO REBOOT FOR SECURITY AND BUGFIX PATCHES IN XX:XX FORMAT
    {% set SECURITY_REBOOT_TIME = "04:30" %}

    # =========================
    # END OF SETTING VARIABLES
    ```

9. The following command launches a free tier e2-micro VM named "pbx". Replace `e2-micro` in this command with another instance type if the free tier isn't desired:
    
    ```bash
    gcloud compute instances create pbx \
        --zone=$ZONE \
        --machine-type=e2-micro \
        --address=pbx-external-ip \
        --tags=pbx \
        --boot-disk-size=30 \
        --image-family=ubuntu-2404-lts-amd64 \
        --image-project=ubuntu-os-cloud \
        --metadata-from-file=user-data=cloud-init.yaml
    ```

> [!TIP]
> <img align="right" alt="Delete" width="50" src="./images/icons8-information-100.png" />
> In the steps below, `--source-ranges` can be any number of globally routable IPv4 addresses written as individual IPs, or groups of IPs in slash notation, separated by commas. For example: `192.178.0.0/15,142.251.47.238`
>
> For convenience, some `--source-ranges` in the steps below fetch the globally routable IPv4 address of the machine where the command was run, using an Amazon AWS service. Remove `$(wget -qO- http://checkip.amazonaws.com)` if that is not an appropriate assumption, and replace it with the correct IP address(es) and/or IP address ranges written in slash notation.

10. Allow HTTP access to the FreePBX web interface from IPs specified in `--source-ranges`. Including `icmp` in `--rules` is optional, it enables the **ping** command to reach the VM from `--source-ranges` IP(s):

    ```bash
    gcloud compute firewall-rules create allow-management-http-icmp \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="$(wget -qO- http://checkip.amazonaws.com)" \
        --rules="tcp:80,icmp" \
        --description="Access FreePBX via HTTP and ping"
    ```

11. Allow SIP registration and RTP & UDPTL media streams over the default UDP port ranges for ATAs and softphones from IPs specified in `--source-ranges`. The `$(wget -qO- http://checkip.amazonaws.com)` command assumes the machine where this command is run also shares the same Internet connection as the softphones and devices that will connect to this PBX.

    ```bash
    gcloud compute firewall-rules create allow-devices-sip-rtp-udptl \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="$(wget -qO- http://checkip.amazonaws.com)" \
        --rules="udp:5060,udp:4000-4999,udp:10000-20000" \
        --description="SIP signaling and RTP & UDPTL media for ATA and Softphone"
    ```

12. Allow RTP and UDPTL media streams over Asterisk's configured UDP port ranges. [Flowroute](https://flowroute.com) uses direct media delivery to ensure voice data streams traverse the shortest path between the caller and callee, the `--source-ranges="0.0.0.0/0"` allows inbound traffic from anywhere in the world. [Telnyx](https://telnyx.com) and [T38Fax](https://t38fax.com) proxy all the RTP and UDPTL media streams through their network for observability into the quality of the RTP streams.

    #### Flowroute

    ```bash
    gcloud compute firewall-rules create allow-flowroute-rtp-udptl \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="0.0.0.0/0" \
        --rules="udp:4000-4999,udp:10000-20000" \
        --description="Incoming RTP and UDPTL media streams from Flowroute"
    ```

    The Flowroute incoming RTP and UDPTL media streams firewall rule permits incoming UDP traffic to Asterisk's RTP and UDPTL ports from any IP address in the world. It is so permissive that the following Telnyx and T38Fax specific ingress rules are redundant, but included for below for completeness:

    #### Telnyx

    ```bash
    gcloud compute firewall-rules create allow-telnyx-rtp-udptl \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="36.255.198.128/25,50.114.136.128/25,50.114.144.0/21,64.16.226.0/24,64.16.227.0/24,64.16.228.0/24,64.16.229.0/24,64.16.230.0/24,64.16.248.0/24,64.16.249.0/24,103.115.244.128/25,185.246.41.128/25" \
        --rules="udp:4000-4999,udp:10000-20000" \
        --description="Incoming RTP and UDPTL media streams from Telnyx"
    ```

    #### T38Fax

    ```bash
    gcloud compute firewall-rules create allow-t38fax-rtp-udptl \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="8.20.91.0/24,130.51.64.0/22,8.34.182.0/24" \
        --rules="udp:4000-4999,udp:10000-20000" \
        --description="Incoming RTP and UDPTL media streams from T38Fax"
    ```

13. Allow SIP signaling for inbound calls from Flowroute, Telnyx, and T38Fax when using IP authentication for those SIP trunks.

    #### Flowroute

    ```bash
    gcloud compute firewall-rules create allow-flowroute-sip \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="34.210.91.112/28,34.226.36.32/28,16.163.86.112/30,3.0.5.12/30,3.8.37.20/30,3.71.103.56/30,18.228.70.48/30" \
        --rules="udp:5060" \
        --description="Flowroute SIP Signaling"
    ```

    #### Telnyx

    ```bash
    gcloud compute firewall-rules create allow-telnyx-sip \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="192.76.120.10,64.16.250.10,185.246.41.140,185.246.41.141,103.115.244.145,103.115.244.146,192.76.120.31,64.16.250.13" \
        --rules="udp:5060" \
        --description="Telnyx SIP Signaling"
    ```

    #### T38Fax

    ```bash
    gcloud compute firewall-rules create allow-t38fax-sip \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="8.20.91.0/24,130.51.64.0/22,8.34.182.0/24" \
        --rules="udp:5060" \
        --description="T38Fax SIP Signaling"
    ```

13. Observe the installation progress by tailing `/var/log/cloud-init-output.log` on the VM:
    
        gcloud compute ssh pbx --zone $ZONE --command "tail -f /var/log/cloud-init-output.log"
    
14. First time gcloud CLI users will be prompted for a passphrase twice. This password can be left blank, press **Enter** twice to proceed:
    
    > ```text
    > WARNING: The private SSH key file for gcloud does not exist.
    > WARNING: The public SSH key file for gcloud does not exist.
    > WARNING: You do not have an SSH key for gcloud.
    > WARNING: SSH keygen will be executed to generate a key.
    > Generating public/private rsa key pair.
    > Enter passphrase (empty for no passphrase):
    > Enter same passphrase again:
    > ```
    
15. A reboot may be required during the cloud-init process. The following output indicates a reboot will be performed:
    
    > ```text
    > 2023-08-20 17:30:04,721 - cc_package_update_upgrade_install.py[WARNING]: Rebooting after upgrade or install per /var/run/reboot-required
    > ```
    
    If the **ubuntu-2404-lts-amd64** Ubuntu image in Google Cloud, specified in step 9 in the `--image-family` parameter, does not contain all the security patches published by Canonical in the last 24 hours, and `package_reboot_if_required: true` in cloud-init.yaml, a reboot may occur.
    
16. In the event of a reboot, re-run the tail command to continue observing the progress of the installation; otherwise skip this step:
    
        gcloud compute ssh pbx --zone $ZONE --command "tail -f /var/log/cloud-init-output.log"
    
17. Press `CTRL + C` to terminate the tail process when it stops producing new output, and prints a `finished at` line:
    
    > ```text
    > Cloud-init v. 24.1.3-0ubuntu3.3 finished at Thu, 20 Jun 2024 03:53:16 +0000. Datasource DataSourceGCELocal.  Up 666.00 seconds
    > ```

18. Visit the PBX external IP to finalize the configuration of FreePBX and set up your Trunks and Extensions. This command will print the hostname for your VM as a hyperlink, CTRL+Click to open:

        dig +short -x $(gcloud compute addresses describe pbx-external-ip --region=$REGION --format='get(address)') | sed 's/\.$//; s/^/http:\/\//'

19. Connect to the pbx VM via SSH:

        gcloud compute ssh pbx --zone $ZONE

    Upon logging in via SSH, connect to the Asterisk CLI, and observe output as you configure and use FreePBX:

        sudo su -s /bin/bash asterisk -c 'cd ~/ && asterisk -rvvvvv'

20. Configure FreePBX. It is time to set up Trunks and Extensions for voice-over-IP and fax-over-IP.

<br><br><sub>PROGRESS: DONE :tada:</sub><br><br><a href="#step-1"><img alt="Done Checkbox" width="25" src="./images/icons8-checked-radio-button-100.png" /><img alt="Step 1" height="25" src="./images/step1.png" /><img alt="" height="25" src="./images/dash.png" /></a><a href="#step-2"><img alt="" height="25" src="./images/dash.png" /><img alt="Done Checkbox" width="25" src="./images/icons8-checked-radio-button-100.png" /><img alt="Step 2" height="25" src="./images/step2.png" /><img alt="" height="25" src="./images/dash.png" /></a><a href="#step-3"><img alt="" height="25" src="./images/dash.png" /><img alt="Done Checkbox" width="25" src="./images/icons8-checked-radio-button-100.png" /><img alt="Step 3" height="25" src="./images/step3.png" /></a>

<hr>

<img alt="Delete" width="50" src="./images/icons8-delete-100.png" />

## **HOW DO I UNDO?**
### How to delete things in Google Cloud

> [!WARNING]
> <img align="right" alt="Delete" width="50" src="./images/icons8-warning-100.png" />
> The following steps are destructive, and will remove everything created by following the above steps, in Google Cloud.

The following steps remove the "pbx" VM, its static IP address, and its firewall rules.

1. List all VMs in this project:

       gcloud compute instances list

2. To delete the "pbx" VM, update `ZONE` if not set already, to reflect what was specified in Step 5:

       ZONE=us-east1-b
       gcloud compute instances delete pbx --zone $ZONE

3. List all the static addresses:
    
       gcloud compute addresses list

4. To delete the address named "pbx-external-ip", update `REGION` if not set already, to reflect what was specified in Step 5:

       REGION=us-east1
       gcloud compute addresses delete pbx-external-ip --region=$REGION

5. List all firewall rules in this project:
    
       gcloud compute firewall-rules list

6. To delete the firewall rules we created earlier:

       gcloud compute firewall-rules delete allow-management-http-icmp
       gcloud compute firewall-rules delete allow-devices-sip-rtp-udptl
       gcloud compute firewall-rules delete allow-flowroute-rtp-udptl
       gcloud compute firewall-rules delete allow-telnyx-rtp-udptl
       gcloud compute firewall-rules delete allow-t38fax-rtp-udptl
       gcloud compute firewall-rules delete allow-flowroute-sip
       gcloud compute firewall-rules delete allow-telnyx-sip
       gcloud compute firewall-rules delete allow-t38fax-sip

<br><br><br><br>
<a href="https://icons8.com"><img alt="icon credits" align="right" src="./images/icons.png"></a>