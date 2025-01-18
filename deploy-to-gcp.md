# Deploy an Ubuntu PBX to Google Public Cloud's always free tier

## Install and configure the gcloud CLI

This guide assumes you are running the following commands in a Linux environment. Windows or macOS users can get an instant Linux virtual machine on their computer with [Multipass](https://multipass.run/install).

1.  Install the [gcloud CLI](https://cloud.google.com/sdk/docs/install)

        sudo snap install google-cloud-cli --classic

2.  Connect gcloud CLI with your Google Cloud account

        gcloud init

    1. Enter **Y** when prompted with *Would you like to log in (Y/n)?*
    2. Visit the authentication link which starts with `https://accounts.google.com/`
    3. Sign in with a Google account
    4. Click **Allow** to grant access to the Google Cloud SDK
    5. Click **Copy** to copy the verification code
    6. Paste the verification code into the terminal window where the `gcloud init` process is running

    If you complete the `gcloud init` process successfully, you will receive the following output:

    > ```text
    > You are now logged in as [your@email.com].
    > Your current project is [None].  You can change this setting by running:
    > $ gcloud config set project PROJECT_ID
    > ```

## Provision resources and deploy

1. List the projects that are in your account:
    
       gcloud projects list
    
    You’ll receive output similar to:
    
    > ```text
    > PROJECT_ID        NAME              PROJECT_NUMBER
    > project-id        project-name      12345678910
    > ```
    
2. Set your Project ID to the `PROJECT_ID` environment variable. Replace `project-id` with your personal Project ID from the previous output:
    
       PROJECT_ID=project-id
    
    This step isn’t required, but it’s recommended because the `PROJECT_ID` variable is used often.
    
3. Associate gcloud CLI to this `PROJECT_ID`:
    
       gcloud config set project $PROJECT_ID
    
    This is where the PBX virtual machine (VM) will be launched.
    
4. List the available cloud zones and cloud regions where VMs can be run:
    
       gcloud compute zones list
    
    You’ll receive output similar to:
    
    > ```text
    > NAME                       REGION                   STATUS  NEXT_MAINTENANCE  TURNDOWN_DATE
    > us-east1-b                 us-east1                 UP
    > ```
    
5. Only `us-west1`, `us-central1`, and `us-east` regions qualify for Google Cloud's free tier. Set the `ZONE` and `REGION` environment variables by replacing `us-east1-b` and `us-east1` in the example commands below, with your desired zone and region:
    
    ```bash
    ZONE=us-east1-b
    REGION=us-east1
    ```
    
6. Reserve a static IP address and label it "pbx-external-ip":
    
       gcloud compute addresses create pbx-external-ip --region=$REGION
    
7. Use curl to download the cloud-init YAML.

       curl -s https://raw.githubusercontent.com/rajannpatel/ubuntupbx/refs/heads/main/cloud-init.yaml

8. Open the file in an editor to change configurations specified between lines 4 and 42. Setting `TOKEN` with an [Ubuntu Pro token](https://ubuntu.com/pro/dashboard) is strongly recommended, and results in [Livepatch](https://ubuntu.com/security/livepatch) being successfully enabled.

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

    # =========================
    # END OF SETTING VARIABLES
    ```

9. Run the following command to launch an e2-micro virtual machine named "pbx":
    
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

10. Allow HTTP access to the FreePBX web interface from your current IPv4 IP address:

    ```bash
    gcloud compute firewall-rules create allow-management-http \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="$(wget -qO- http://checkip.amazonaws.com)" \
        --rules="http:80" \
        --description="FreePBX Web Portal"
    ```

11. Allow your "pbx" virtual machine to receive incoming UDP connections from your devices. This command assumes your ATAs or Softphones are at your IP address. Replace or add additional IP addresses after `$(wget -qO- http://checkip.amazonaws.com)` in a comma and space separated format.

    ```bash
    gcloud compute firewall-rules create allow-telnyx-sip \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="$(wget -qO- http://checkip.amazonaws.com)" \
        --rules="udp:5060" \
        --description="ATA and Softphone SIP Signaling"
    ```

12. Allow your "pbx" virtual machine to receive incoming UDP and TCP connections from providers.

    ```bash
    gcloud compute firewall-rules create allow-asterisk-rtp \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="0.0.0.0/0" \
        --rules="udp:10000-20000" \
        --description="Asterisk RTP Media Ports"
    ```

    #### Telnyx

    ```bash
    gcloud compute firewall-rules create allow-telnyx-sip \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="192.76.120.10, 64.16.250.10, 185.246.41.140, 185.246.41.141, 103.115.244.145, 103.115.244.146, 192.76.120.31, 64.16.250.13" \
        --rules="udp:5060, tcp:5060, tls:5061" \
        --description="Telnyx TCP, UDP, and TLS SIP Signaling"
    ```

    ### Flowroute

    ```bash
    gcloud compute firewall-rules create allow-flowroute-sip \
        --direction=INGRESS \
        --action=ALLOW \
        --target-tags=pbx \
        --source-ranges="34.210.91.112/28, 34.226.36.32/28, 16.163.86.112/30, 3.0.5.12/30, 3.8.37.20/30, 3.71.103.56/30, 18.228.70.48/30" \
        --rules="udp:5060, tcp:5060, udp:5160, tcp:5160" \
        --description="Flowroute TCP and UDP SIP Signaling"
    ```

13. Observe the progress of your installation by tailing the `/var/log/cloud-init-output.log` file on the virtual machine:
    
        gcloud compute ssh pbx --zone $ZONE --command "tail -f /var/log/cloud-init-output.log"
    
14. If you are a first time gcloud CLI user, you’ll be prompted for a passphrase twice. This password can be left blank, press **Enter** twice to proceed:
    
    > ```text
    > WARNING: The private SSH key file for gcloud does not exist.
    > WARNING: The public SSH key file for gcloud does not exist.
    > WARNING: You do not have an SSH key for gcloud.
    > WARNING: SSH keygen will be executed to generate a key.
    > Generating public/private rsa key pair.
    > Enter passphrase (empty for no passphrase):
    > Enter same passphrase again:
    > ```
    
15. A reboot may be required during the cloud-init process. If a reboot is required, you’ll receive the following output:
    
    > ```text
    > 2023-08-20 17:30:04,721 - cc_package_update_upgrade_install.py[WARNING]: Rebooting after upgrade or install per /var/run/reboot-required
    > ```
    
    If the `IMAGE_FAMILY` specified earlier contained all the security patches, this reboot step may not occur.
    
16. Repeat the following code if a reboot was necessary to continue observing the progress of the installation:
    
        gcloud compute ssh pbx --zone $ZONE --command "tail -f /var/log/cloud-init-output.log"
    
17. Wait until the cloud-init process is complete. When it's complete, you’ll receive two lines similar to this:
    
    > ```text
    > Cloud-init v. 24.1.3-0ubuntu3.3 finished at Thu, 20 Jun 2024 03:53:16 +0000. Datasource DataSourceGCELocal.  Up 666.00 seconds
    > ```
    
18. Press `CTRL + C` to terminate the tail process in your terminal window.

## How to delete everything, if you wish to start over

**THE FOLLOWING STEPS WILL DELETE WHAT YOU HAVE CREATED, ABOVE**

This is how to remove the "pbx" VM, its static IP address, and its firewall rules.

1. List all the addresses you’ve created:
    
       gcloud compute addresses list

2. To delete the address named "pbx-external-ip" we created earlier:

       gcloud compute addresses delete pbx-external-ip --region=$REGION

3. List all VMs in this project:

       gcloud compute instances list

4. To delete the "pbx" VM we created earlier:

       gcloud compute instances delete INSTANCE_NAME --zone $ZONE

5. List all firewall rules in this project:
    
       gcloud compute firewall-rules list

6. To delete the firewall rules we created earlier:

       gcloud compute firewall-rules delete <NAME-OF-RULE>
