<div align="center">
  <h1>APProVe <sup>by iBDF</sup></h1>
</div>

This guide will walk you through the local deployment of APProVe. Some connections need to be changed to run the Docker deployment locally and imitate the reverse proxying needed to run APProVe.


[[_TOC_]]

<p align="center">
  <a href="#">
    <img src="https://gitlab.ibdf-frankfurt.de/uct/open-approve/-/raw/master/img/Project_management-APProVe_en.png" alt="Workflow" style="height: 120px; width: 120px">
  </a>
</p>

## System Requirements
- RAM: 6GB
- Multi-core processor (e.g., Intel i5)
- Hard disk space: 500 MB

## What it Does
This guide helps create a basic deployment with required services (user and manual are optional but included to avoid errors). It also creates a Realm named "test" in Keycloak and automatically adds the Keycloak SPI.

## Installing APProVe
We've created a script to guide you through the installation. You can find it in this repository or at this link: [Install Script](https://gitlab.ibdf-frankfurt.de/uct/open-approve/-/blob/master/install.sh).

### Edit Your Hosts File
To run the network with localhost, you need to edit your hosts file. Here are the necessary entries:

On Windows and Ubuntu, you can find the hosts file in different locations:

**For Windows**:
Windows 11/10/8/7/Vista:
- The hosts file is located at C:\Windows\System32\drivers\etc\hosts.
- You'll need administrator privileges to edit this file. Make sure to open your text editor as an administrator to modify it.

**For Ubuntu and Other Linux Distributions**:
- The hosts file on Linux-based systems, including Ubuntu, is located in the /etc directory.
- The full path to the hosts file is: /etc/hosts.
- To edit the hosts file on Ubuntu, you will need superuser privileges. You can use a text editor with superuser rights, like sudo nano, to modify the file.

Here's an example command to open and edit the hosts file on Ubuntu using the nano text editor:
````shell
sudo nano /etc/hosts
````

```yml
127.0.0.1 approve.backend
127.0.0.1 approve.auth
127.0.0.1 approve.user
127.0.0.1 approve.frontend
127.0.0.1 approve.comment
127.0.0.1 approve.mails
127.0.0.1 approve.automation
127.0.0.1 approve.import
127.0.0.1 approve.draft
```

Afterward, you can use the container_name in APProVe as localhost. The container localhost is different from the hosts' localhost because it is inside the container. 
However, you can use the container_name for the localhost inside the container to access other services.

For example:
http://approve.frontend:8001 or http://approve.auth:8080

## Limitations
Currently, it's not possible to change the Keycloak URL to a different port, so port 8080 should be free before a local deployment. 
The use of the hosts file to emulate localhost calls will be addressed in the future.

