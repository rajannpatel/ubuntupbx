Instead of installing the Google Cloud CLI software directly on your Ubuntu workstation, compartmentalizing the local workspace into containers improves security, efficiency, and keeps the workspace clean and organized. [LXD](https://canonical.com/lxd/install) is a system container and virtual machine manager. It's built on top of LXC (Linux Containers) but provides a more user-friendly and feature-rich experience. Think of LXD as the tool you use to manage LXC containers, making it easier to create, configure, and run them.   

Launch a LXD container named **gcp-ubuntupbx** and map your user account on the host machine to the default **ubuntu** user account in the container:
```bash
lxc launch ubuntu:noble gcp-ubuntupbx -c raw.idmap="both 1000 1000"
```

Optional Step: mount your home directory into the container as a disk named "ubuntupbx-home", to conveniently access your files from within the container:
```bash
lxc config device add gcp-ubuntupbx ubuntupbx-home disk source=~/ path=/home/ubuntu
```

Enter the LXD container as the **ubuntu** user:
```bash
lxc exec gcp-ubuntupbx -- su -l ubuntu
```

You are ready to begin [Step 1](./README.md#install-and-configure-the-gcloud-cli).