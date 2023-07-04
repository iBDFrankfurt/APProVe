<div align="center">
  <b>APProVe <sup>by iBDF</sup></b>
  <br>
</div>
<br>
<br>

This guide will lead you to the minimal local deployment of APProVe. Some connection have to be changed in order to run the docker 
deployment locally. 


**This is the complete deployment, if you want to test your System first please refer to [Minimal Deployment Guide](https://gitlab.proskive.de/uct/open-approve/-/tree/master/minimal-local-setup)**


[[_TOC_]]


<p align="center">
  <a href="#">
    <img src="https://gitlab.ibdf-frankfurt.de/uct/open-approve/-/raw/master/img/Project_management-APProVe_en.png" alt="WorkFlow" style="height: 120px; width: 120px">
  </a>
</p>

## System Requirements
* RAM 6GB
* Multi-core processor (e.g. Intel i5)
* 500 MB hard disk space

## What it does
Creating a basic deployment with needed services (user and manual is optional, but for the sake of not printing to many errors i added them).
It will also create a Realm ``test`` in Keycloak and add the Keycloak SPI automatically.


## Installing APProVe
We created a script to help you guide through the installation. You can find it in this repository or under this link: https://gitlab.ibdf-frankfurt.de/uct/open-approve/-/blob/master/install.sh


### Edit your hosts file
In order to run the network with localhost you must edit your hosts file.
(/etc/hosts on Mac/Linux, c:\Windows\System32\Drivers\etc\hosts on Windows)

And add these entries:

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

After that we can use the container_name in APProVe as localhost. The container localhost is different from the hosts localhost because it is inside the container. But we can use the container_names for the localhost inside the container to reach other services.


## Limitations
Currently, I was not able to change the Keycloak URl to a different port, so 8080 should be free before a local 
deployment.
Using the hosts file to imitate localhost calls will be fixed in the future.

