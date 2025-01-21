# Project overview for Ubuntu PBX

FreePBX is an open source, web based graphical user interface (GUI) that simplifies the deployment and management of Asterisk, a telephony engine and private branch exchange platform. Sangoma, the publisher of Asterisk and FreePBX, uses Debian as the target operating system for FreePBX installations.

## Why should I install FreePBX and Asterisk on Ubuntu?

Canonical, the publisher of Ubuntu, also publishes source code and compiled packages for almost 30,000 open source software titles to the official Ubuntu repositories. This open source software can be installed on Ubuntu with **apt** or **apt-get**.

Anyone deploying FreePBX on Ubuntu benefits from the 10 years of long-term security patching of every open source dependency in Asterisk and FreePBX that is installed from Canonical's Ubuntu repositories, or its mirrors. Sangoma security patches Asterisk LTS versions for 4 years. As an alternative to installing Asterisk from Sangoma, performing `apt install asterisk` on Ubuntu results in an installation Asterisk and all its open source dependencies that get in-place security patches from Canonical for 10 years.

Anybody running Ubuntu 24.04 with an Ubuntu Pro subscription (free, or paid) will get security updates for packages installed from Canonical repositories until April 2034. Even though the stewards of Asterisk, NodeJS, and others have shifted focus to newer versions of their software, you can rely on Canonical to provide security updates until 2034. 

> “Since we first launched Ubuntu LTS, with five years free security coverage for the main OS, our enterprise customers have asked us to cover more and more of the wider open-source landscape under private commercial agreements. Today, we are excited to offer the benefits of all of that work, free of charge, to anyone in the world, with a free personal Ubuntu Pro subscription”
> - Mark Shuttleworth, CEO of Canonical.

Ubuntu 24.04 ships with PHP 8.3 and Node.js 18.19. FreePBX 17 is compatible with Node.js 18.19, but is unable to run on PHP 8.3. PHP 8.2 must be installed, and is available from Ondřej Surý's PHP PPA. Ondřej Surý is a Debian developer whose Ubuntu PPA is a reliable source for alternative PHP versions. It's worth noting, Ondřej Surý becomes your source for PHP 8.2 security updates if you choose to install their PHP 8.2 packages on your machine.

Canonical has an 18-year track record of timely security updates for the main Ubuntu OS, with critical CVEs patched in less than 24 hours on average. Ubuntu Pro expands this coverage to include software installed from the universe repository. Patches are applied for critical, high, and selected medium CVEs, with many zero-day vulnerabilities fixed under embargo for release the moment the CVE is public.

## What is the best way to install FreePBX and Asterisk on Ubuntu?

With this project, you can deploy FreePBX 17 and Asterisk 20.6 on Ubuntu 24.04 LTS using modern Infrastructure as Code (IaC) best practices. This repository contains a single version controlled, declarative, and idempotent cloud-init.yaml configuration file. Fork this repository and modify the first few lines of the cloud-init.yaml to reflect your environment's configuration.

Cloud-init provides event-driven execution, and installing FreePBX and Asterisk with cloud-init ensures configurations and installations happen in the correct sequence. There is guaranteed idempotence when using cloud-init's modules, and cloud-init's declaritive configurations provide improved security over scripted configurations from shell scripts downloaded from the Internet.

The cloud-init.yaml configurations are opinionated, and strive to:

- compile nothing from source; rather install via Ubuntu's apt or snap package managers
- keep the installation and configuration as lean as possible
- prevent the disk from becoming full through normal long-term usage of Asterisk and FreePBX
- enable automated security and bugfix updates every 3:00AM for FreePBX dependencies installed using apt
- be resilient against race conditions when installing on low-compute-power shared-core VMs, such as Google's f1-micro.
- pre-configure the FreePBX Core Module to:
  - unload Asterisk modules which are not suitable for containerized or virtual machine deployments
  - include Flowroute and Telnyx SIP trunks with IP authentication, leaving only the Outbound Dialing Prefix to be manually set
  - include outbound routes for making calls anywhere in North America, with Flowroute and Telnyx failover
  - **TODO** configure incoming caller ID to conform to North American Numbering Plan (e.164 NANPA)
- configure Ubuntu to run for 9 months without reboot
  - enable Livepatch for protecting the Linux kernel
  - prune call recordings over 45 days old via crontab, if call recording is enabled
  - prune CDR and CEL records over 24 hours old via crontab

## How do I deploy FreePBX and Asterisk with cloud-init?

All cloud providers provide the ability to configure virtual machines via cloud-init in their dashboard, via command line tools, or both. 

### Google Cloud Platform

### Provisioning via the gcloud command line utility

- [How to install and configure FreePBX and Asterisk on Google Cloud with Google's gcloud utility, and cloud-init.](./deploy-to-gcp.md)

### Provisioning via the GCP Dashboard

Google Cloud Platform's dashboard looks like this when provisioning a virtual machine:

![Expand the Management, security, disks, networking, sole tenancy section](https://blog.woohoosvcs.com/wp-content/uploads/2019/11/GCE-FindAutomation.jpg)

Click "Add item" under Management

![add a user-data key](https://blog.woohoosvcs.com/wp-content/uploads/2019/11/GCE-Automation.jpg)

You can paste the [cloud-init.yaml](./cloud-init.yaml) configuration file in that text area.

### Oracle Cloud Infrastructure

Oracle Cloud Infrastructure's dashboard looks like this when provisiong a new virtual machine:

![add cloud-init to Oracle Cloud](https://miro.medium.com/max/1100/1*dfBpaXvB2YRDRQVBInFn5w.png)

You can paste the [cloud-init.yaml](./cloud-init.yaml) configuration file in that text area.