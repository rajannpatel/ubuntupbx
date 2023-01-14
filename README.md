# Ubuntu PBX

This project contains a collection of cloud-init.yaml and bash scripts which can be used configure and install FreePBX and Asterisk on Ubuntu in any cloud, virtual machine, or bare metal environment.

Our goal is to install as much software as possible from Canonical, instead of other sources.

Ubuntu 22.04 is the only option for deploying to ARM64 machines, due to a software bug resulting in the odbc-mariadb package not being available for ARM64 machines running Ubuntu 20.04. The Compatibility Matrix section, below, contains more information about this.

#### Table of Contents
- [Installation](#installation)
    - [Using install.sh](#using-installsh)
    - [Using cloud-init](#using-cloud-init)
- [Applying Security Patches and Updates](#applying-security-patches-and-updates)
- [Overview](#overview)
    - [Why use Sangoma OS?](#why-use-sangoma-os)
    - [Why use Ubuntu?](#why-use-ubuntu)
    - [Compatibility Matrix](#compatibility-matrix)
    - [Security Patching Matrix](#security-patching-matrix)

---

## Installation

Cloud-init is a tool that is designed to perform initialization tasks on a virtual or physical machine when it is first launched. These tasks can include setting the hostname, installing packages, writing files, and configuring the operating system and the installed software.

It is generally considered to be a security risk to curl and run a shell script from the Internet without thoroughly reviewing and understanding its contents first.

Please familiarize yourselves the contents of the cloud-init.yaml file or install.sh files in this project before using them. You only need to use either the cloud-init.yaml file or the install.sh. Downloading and running install.sh may be the more familiar path for some of you, but cloud-init.yaml is the fastest one.

| Ubuntu 20.04&nbsp;&nbsp;&nbsp;<img src="https://assets.ubuntu.com/v1/28e0ebb7-Focal-Fossa-gradient-outline.svg" height="16" align="right"> | Ubuntu 22.04&nbsp;&nbsp;&nbsp;<img src="https://assets.ubuntu.com/v1/4d42e36c-Jammy+Jellyfish+RGB.svg" height="16" align="right"> |
|---                    |---                      |
| [cloud-init.yaml](./focal/cloud-init.yaml)     | [cloud-init.yaml](./jammy/cloud-init.yaml) |
| [install.sh](./focal/install.sh)   | [install.sh](./jammy/install.sh) |

### Using install.sh

1. Clone the rajannpatel/ubuntupbx git repository
```console
git clone --depth 1 https://github.com/rajannpatel/ubuntupbx.git
```

2. change to the directory with files intended for your version of Ubuntu
```console
cd "ubuntupbx/$(env -i bash -c '. /etc/os-release; echo $VERSION_CODENAME')/"
```

3. read the install.sh script, and then run it
```console
sudo bash install.sh
```

### Using cloud-init

All cloud providers provide the ability to configure virtual machines via cloud-init in their dashboard, via command line tools, or both. For example, Oracle Cloud Infrastructure's dashboard looks like this when provisiong a new virtual machine:

![add cloud-init to Oracle Cloud](https://miro.medium.com/max/1100/1*dfBpaXvB2YRDRQVBInFn5w.png)

You can paste the Ubuntu Jammy [cloud-init.yaml](./jammy/cloud-init.yaml) configuration file in that text area.

Beyond public cloud, cloud-init configuration files are a subset of Juju configuration files, if you happen to be using Juju to automate your application deployment and lifecycle. Cloud-init files can be passed to Multipass virtual machine instances, and even to LXD containers.

---

### Applying Security Patches and Updates

#### Upgrading

Take a backup before attempting to upgrade. It is possible to do this using the FreePBX Backup module.

The following commands should be run as root.

First, update all the software packages installed from Canonical:

```console
apt-get update --fix-missing
apt-get -y upgrade
```

Second, update the software whose source code you downloaded from Canonical, but built from source.

- Upgrading / Changing between Asterisk 16 versions on Ubuntu 20.04

```console
cd /tmp && curl -O http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-16-current.tar.gz
ASTERISK_16_VERSION=$(printf "%s"$'\n' /usr/src/asterisk* | sort -Vr | head -n1)
mv $($ASTERISK_16_VERSION)/ /usr/src && cd $($ASTERISK_16_VERSION)
make distclean
./configure --with-jansson-bundled
make menuselect.makeopts
menuselect/menuselect --enable app_macro --enable CORE-SOUNDS-EN-ULAW --enable MOH-OPSOUND-ULAW --enable EXTRA-SOUNDS-EN-ULAW --disable-category MENUSELECT_CDR --disable-category MENUSELECT_CEL --disable res_snmp --disable chan_dahdi menuselect.makeopts
rm -rf /usr/lib/asterisk/modules/*
make && make install && chown -R asterisk. /var/lib/asterisk
fwconsole ma install core
fwconsole restart
```

- Upgrading / Changing between Asterisk 18 versions on Ubuntu 22.04

```console
cd /tmp && curl -O http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-18-current.tar.gz
ASTERISK_18_VERSION=$(printf "%s"$'\n' /usr/src/asterisk* | sort -Vr | head -n1)
mv $($ASTERISK_18_VERSION)/ /usr/src && cd $($ASTERISK_18_VERSION)
make distclean
./configure --with-jansson-bundled
make menuselect.makeopts
menuselect/menuselect --enable app_macro --enable CORE-SOUNDS-EN-ULAW --enable MOH-OPSOUND-ULAW --enable EXTRA-SOUNDS-EN-ULAW --disable-category MENUSELECT_CDR --disable-category MENUSELECT_CEL --disable res_snmp --disable chan_dahdi menuselect.makeopts
rm -rf /usr/lib/asterisk/modules/*
make && make install && chown -R asterisk. /var/lib/asterisk
fwconsole ma install core
fwconsole restart
```

And third, update all the FreePBX modules:

```console
fwconsole ma updateall && fwconsole reload
```

#### Restoring

When restoring from backup, the restoration process may fail. Set permissions and re-run the restore:

```console
fwconsole chown
```

---

## Overview

FreePBX is a web-based dashboard that controls Asterisk. Both FreePBX and Asterisk are open source software that allows anyone to build a telephone system. Software like FreePBX and Asterisk have dependencies on other open source software. Asterisk was created in 1999 and maintained by Digium, and FreePBX was created in 2004 and maintained by Schmooze. Through acquisitions, Sangoma became the commercial entity behind FreePBX as of 2010, and Asterisk as of 2018.

A common way to install FreePBX is through Sangoma's operating system, which is based on CentOS 7.8.2003. It is trivial to launch FreePBX on public cloud and elsewhere in under 5 minutes via cloud-init.yaml configuration scripts, on any Linux of your choosing. The following 2 sections may help you decide what operating system you want to run FreePBX on, if you choose to run FreePBX on Ubuntu, this project contains cloud-init.yaml files which install FreePBX on currently supported Ubuntu LTS releases.

### Why use Sangoma OS?

Users interested in Sangoma's commercial support and software offerings are required to use FreePBX on Sangoma's CentOS 7.8.2003 based operating system.

From a security patching perspective, when using Sangoma's CentOS derivative operating system, you rely on Sangoma to backport security patches from CentOS 7.9, and make them available in their CentOS 7.8.2003 derived Sangoma OS. CentOS 7.9 is the final subrelease of CentOS 7, and it will reach end of life in June 2024.

### Why use Ubuntu?

Users interested in only the open source aspects of FreePBX and Asterisk have the option to install this software on Ubuntu.

FreePBX 16 has a hard requirement on PHP 7.4 and Node.js 10. PHP 7.4 went end-of-life in November 2022, and Node.js 10 went end-of-life in April 2021. Asterisk 16 will reach end-of-life in October 2023, and Asterisk 18 reaches end-of-life in October 2025.

Anybody running Ubuntu 20.04 with an Ubuntu Pro subscription (free, or paid) will get security updates for software installed from the "main" and "universe" repositories until April 2030. Even though the stewards of PHP, Asterisk and others have shifted focus to newer versions, you can rely on Canonical to provide security updates for PHP 7.4 and Asterisk 16.2 until 2030. 

> “Since we first launched Ubuntu LTS, with five years free security coverage for the main OS, our enterprise customers have asked us to cover more and more of the wider open-source landscape under private commercial agreements. Today, we are excited to offer the benefits of all of that work, free of charge, to anyone in the world, with a free personal Ubuntu Pro subscription”
> - Mark Shuttleworth, CEO of Canonical.

### Compatibility Matrix

Due to a [software bug involving hardcoded paths](https://bugs.debian.org/942412) to some architecture specific libraries, the odbc-mariadb software package in Ubuntu 20.04 can only install on AMD64/i386 (x86/x86_64) architectures. The fix for ARM64 (aarch64) support in the odbc-mariadb package arrived in Ubuntu 22.04, and is not backported into Ubuntu 20.04.

|               | architecture&nbsp;&nbsp;&nbsp;<img src="https://assets.ubuntu.com/v1/4e0399a1-chip.svg" height="16" align="right">  |  Ubuntu 20.04&nbsp;&nbsp;&nbsp;<img src="https://assets.ubuntu.com/v1/28e0ebb7-Focal-Fossa-gradient-outline.svg" height="16" align="right"> | Ubuntu 22.04&nbsp;&nbsp;&nbsp;<img src="https://assets.ubuntu.com/v1/4d42e36c-Jammy+Jellyfish+RGB.svg" height="16" align="right"> |
|---            |---            |---            |---            |
|odbc-mariadb  	| amd64      	| 3.1.4         | 3.1.15 	    |
|odbc-mariadb  	| arm64      	| not available | 3.1.15 	    |

### Security Patching Matrix

Ubuntu 22.04 ships with PHP 8.1 and Node.js 12.22, FreePBX 16 is unable to run on PHP 8.1, and requires PHP 7.4 to be installed from elsewhere. FreePBX 16 does produce error messages during operation when using Node.js 18.10, so it is recommended to use Node.js 12.

Ondřej Surý is a Debian developer whose Ubuntu PPA is a reliable source for alternative PHP versions. It's worth noting, Ondřej Surý becomes your source for PHP 7.4 security updates if you choose to install their PHP 7.4 package on your machine.

The Node.js snap can be installed at version 12, but PM2 is unable to work when Node.js is installed as a snap. Installing Node.js from Nodesource makes Nodesource your source for Node.js security updates.

Canonical has an 18-year track record of timely security updates for the main Ubuntu OS, with critical CVEs patched in less than 24 hours on average. Ubuntu Pro expands this coverage to include software installed from the universe repository. Patches are applied for critical, high, and selected medium CVEs, with many zero-day vulnerabilities fixed under embargo for release the moment the CVE is public.

#### Where FreePBX dependencies can be installed from:
|               | Ubuntu 20.04&nbsp;&nbsp;&nbsp;<img src="https://assets.ubuntu.com/v1/28e0ebb7-Focal-Fossa-gradient-outline.svg" height="16" align="right"> | Ubuntu 22.04&nbsp;&nbsp;&nbsp;<img src="https://assets.ubuntu.com/v1/4d42e36c-Jammy+Jellyfish+RGB.svg" height="16" align="right"> |
|---            |---                    |---                      |
|PHP  	        | 7.4 from universe     | 7.4 from ppa:ondrej/php |
|Node.js  	    | 12.x from deb.nodesource.com   | 12.22 from universe     |
|Asterisk       | 16.2 from universe    | 18.10 from universe     |
