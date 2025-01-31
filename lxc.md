Instead of installing software directly into Ubuntu, it is preferable to install software into containers, to keep the host operating system as lean and clean as possible.

Launch a LXC container named **gcp-ubuntupbx** and map your user account on the host machine to the **ubuntu** user account in the container:
```bash
lxc launch ubuntu:noble gcp-ubuntupbx -c raw.idmap="both 1000 1000"
```

Optional Step: mount your home directory into the container as a disk, to conveniently access your files from within the container:
```bash
lxc config device add gcp-ubuntupbx ubuntupbx-home disk source=~/ path=/home/ubuntu
```

Enter the LXC container as the **ubuntu** user:
```bash
lxc exec gcp-ubuntupbx -- su -l ubuntu
```

You are ready to begin [Step 1](./README.md#install-and-configure-the-gcloud-cli).