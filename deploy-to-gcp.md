# Install FreePBX 17 on Ubuntu 24.04 with all open-source dependencies installed from Ubuntu's official repositories.

There is no charge to use Google Cloud's Compute Engine up to their specified free usage limit. The free usage limit does not expire, and is perfect for running FreePBX 17 and Asterisk 20.6 on Ubuntu 24.04 LTS. 

## Install and configure the gcloud CLI

The following commands must be executed in a Linux terminal. On Windows and macOS [Multipass](https://multipass.run/install) provides Linux virtual machines on demand.

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

## Provision resources and deploy

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
    
    This Project ID will contain the PBX virtual machine (VM).
    
4. List the available cloud zones and cloud regions where VMs can be deployed:

       gcloud compute zones list

    Output will appear in this format:

    > ```text
    > NAME                       REGION                   STATUS  NEXT_MAINTENANCE  TURNDOWN_DATE
    > us-east1-b                 us-east1                 UP
    > ```

5. Only zones `us-west1`, `us-central1`, and `us-east1` in region `us-east` qualify for Google Cloud's free tier. Set the `ZONE` and `REGION` environment variables with one of the 3 free tier regions in the free tier `us-east1` zone, or select another zone and region combination from the `gcloud compute zones list` output:

    ```bash
    ZONE=us-east1-b
    REGION=us-east1
    ```

6. Reserve a static IP address and label it "pbx-external-ip":
    
       gcloud compute addresses create pbx-external-ip --region=$REGION
    
7. Use curl to download the cloud-init YAML.

       curl -s https://raw.githubusercontent.com/rajannpatel/ubuntupbx/refs/heads/main/cloud-init.yaml -o cloud-init.yaml

8. Open the file in an editor to change configurations specified between lines 4 and 43. Setting `TOKEN` with an [Ubuntu Pro token](https://ubuntu.com/pro/dashboard) is required for security updates to Asterisk, Asterisk's dependencies, and some FreePBX dependencies. [Livepatch](https://ubuntu.com/security/livepatch) will be enabled by this cloud-init.yaml file if a Pro Token is set.

    ```markdown
    # SET OUR VARIABLES
    # =================

    # Ubuntu Pro token from: https://ubuntu.com/pro/dashboard (not needed for Ubuntu Pro instances on Azure, AWS, or Google Cloud)
    {% set TOKEN = '' %}

    # SMTP credentials
    # sendgrid example: substitute `YOUR-API-KEY-HERE` with your API KEY, https://app.sendgrid.com/settings/api_keys
    # {% set SMTP_HOST = 'smtp.sendgrid.net' %}
    # {% set SMTP_PORT = '587' %}
    # {% set SMTP_USERNAME = 'apikey' %}
    # {% set SMTP_PASSWORD = 'YOUR-API-KEY-HERE' %}

    # google mail / gmail example: substitute YOUREMAIL@GMAIL.COM and YOUR-APP-PASSWORD from: https://myaccount.google.com/apppasswords
    # {% set SMTP_HOST = 'smtp.gmail.com' %}
    # {% set SMTP_PORT = '587' %}
    # {% set SMTP_USERNAME = 'YOUREMAIL@GMAIL.COM' %}
    # {% set SMTP_PASSWORD = 'YOUR-APP-PASSWORD' %}

    {% set SMTP_HOST = '' %}
    {% set SMTP_PORT = '' %}
    {% set SMTP_USERNAME = '' %}
    {% set SMTP_PASSWORD = '' %}

    # CRONTAB_EMAIL address for daily crontab notifications
    {% set CRONTAB_EMAIL = 'youremail@example.com' %}

    # HOSTNAME: subdomain of FQDN (e.g. `server` for `server.example.com`)
    # FQDN (e.g. `example.com` or `server.example.com`)
    {% set HOSTNAME = 'voip' %}
    {% set FQDN = 'voip.example.com' %}

    {% set PRETTY_HOSTNAME = "My PBX Server" %}

    # TIMEZONE: default value is fine
    # As represented in /usr/share/zoneinfo. An empty string ('') will result in UTC time being used.
    {% set TIMEZONE = 'America/New_York' %}

    # TIME TO REBOOT FOR SECURITY AND BUGFIX PATCHES IN XX:XX FORMAT
    {% set SECURITY_REBOOT_TIME = "03:00" %}

    # =========================
    # END OF SETTING VARIABLES
    ```

9. The following command launches an e2-micro virtual machine named "pbx":
    
    ```bash
    gcloud compute instances create pbx \
        --zone=$ZONE \
        --machine-type=e2-micro \
        --address=pbx-external-ip \
        --tags=pbx \
        --boot-disk-size=20 \
        --image-family=ubuntu-2404-lts-amd64 \
        --image-project=ubuntu-os-cloud \
        --metadata-from-file=user-data=cloud-init.yaml
    ```

> **NOTE:**
> In the steps below, `--source-ranges` can be any number of globally routable IPv4 addresses written in slash notation, separated with a comma and a space. Example:
> 
> ```
> 192.178.0.0/15, 142.251.47.238
> ```
> 
> For convenience, some `--source-ranges` in the steps below fetch the globally routable IPv4 address of the machine where the command was run, using an Amazon AWS service. Remove `$(wget -qO- http://checkip.amazonaws.com)` if that is not an appropriate assumption, and replace it with the correct IP address(es) and/or IP address ranges written in slash notation.

10. Allow HTTP access to the FreePBX web interface from IPs specified in `--source-ranges`:

    ```bash
    gcloud compute firewall-rules create allow-management-http \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="$(wget -qO- http://checkip.amazonaws.com)" \
        --rules="tcp:80" \
        --description="FreePBX Web Portal"
    ```

11. Allow incoming SIP registration from ATAs and softphones over the standard SIP port and protocl: 5060 UDP, from IPs specified in `--source-ranges`.

    ```bash
    gcloud compute firewall-rules create allow-devices-sip \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="$(wget -qO- http://checkip.amazonaws.com)" \
        --rules="udp:5060" \
        --description="SIP signaling for ATA and Softphone"
    ```

12. Allow RTP media streams over the default UDP port ranges. Flowroute uses direct media delivery to ensure voice data streams traverse the shortest path between the caller and callee. Telnyx proxies all the RTP media streams through their Equinix network to provide observability into the quality of the RTP streams. Direct peering is available between Telnyx and customer datacenters, or to customers' networks in any major public cloud. When restricting `--source-ranges` to Telnyx's media gateways, be mindful that softphones and ATAs also establish RTP connections, and need to be included in this `--source-ranges` list.

    ```bash
    gcloud compute firewall-rules create allow-asterisk-rtp \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="0.0.0.0/0" \
        --rules="udp:10000-20000" \
        --description="Asterisk RTP media streams"
    ```

13. Allow SIP signaling for outbound calls to a VoIP provider, these commands configure the Google Cloud firewall to allow outbound calls with Telnyx and Flowroute. 

    #### Telnyx

    ```bash
    gcloud compute firewall-rules create allow-telnyx-sip \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="192.76.120.10,64.16.250.10,185.246.41.140,185.246.41.141,103.115.244.145,103.115.244.146,192.76.120.31,64.16.250.13" \
        --rules="udp:5060,tcp:5060-5061" \
        --description="Telnyx UDP, TCP, and TCP with TLS Signaling"
    ```

    #### Flowroute

    ```bash
    gcloud compute firewall-rules create allow-flowroute-sip \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="34.210.91.112/28,34.226.36.32/28,16.163.86.112/30,3.0.5.12/30,3.8.37.20/30,3.71.103.56/30,18.228.70.48/30" \
        --rules="udp:5060,tcp:5060,udp:5160,tcp:5160" \
        --description="Flowroute TCP and UDP SIP Signaling"
    ```

13. Observe the installation progress by tailing `/var/log/cloud-init-output.log` on the virtual machine:
    
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
    
    If the `IMAGE_FAMILY` specified earlier contained all the security patches, this reboot step may not occur.
    
16. In the event of a reboot, re-run the tail command to continue observing the progress of the installation; otherwise skip this step:
    
        gcloud compute ssh pbx --zone $ZONE --command "tail -f /var/log/cloud-init-output.log"
    
17. Press `CTRL + C` to terminate the tail process when it stops producing new output, and prints a `finished at` line:
    
    > ```text
    > Cloud-init v. 24.1.3-0ubuntu3.3 finished at Thu, 20 Jun 2024 03:53:16 +0000. Datasource DataSourceGCELocal.  Up 666.00 seconds
    > ```

## How to undo the previous steps, and delete everything

The following steps remove the "pbx" VM, its static IP address, and its firewall rules.

1. List all VMs in this project:

       gcloud compute instances list

2. Delete the "pbx" VM, it is assumed the `ZONE` variable is still set from Step 5:

       gcloud compute instances delete pbx --zone $ZONE

3. List all the static addresses:
    
       gcloud compute addresses list

4. Delete the address named "pbx-external-ip", it is assumed the `REGION` variable is still set from Step 5:

       gcloud compute addresses delete pbx-external-ip --region=$REGION

5. List all firewall rules in this project:
    
       gcloud compute firewall-rules list

6. Delete the firewall rules we created earlier:

       gcloud compute firewall-rules delete allow-management-http
       gcloud compute firewall-rules delete allow-devices-sip
       gcloud compute firewall-rules delete allow-asterisk-rtp
       gcloud compute firewall-rules delete allow-telnyx-sip
       gcloud compute firewall-rules delete allow-flowroute-sip