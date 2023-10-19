<div align="center">
  <b>APProVe <sup>by iBDF</sup></b>
  <br>
</div>
<br>
<br>

This manual will guide you through the process of installing APProVe on a Server Environment.


[[_TOC_]]


<p align="center">
  <a href="#">
    <img src="https://gitlab.ibdf-frankfurt.de/uct/open-approve/-/raw/master/img/Project_management-APProVe_en.png" alt="WorkFlow" style="height: 120px; width: 120px">
  </a>
</p>

## System Requirements
* **RAM** 6GB
* **Multi-core** processor (e.g. Intel i5)
* **500** MB hard disk space
* **NGINX**
* **SSL** Certificate or Certbot
* **1** Domain
* **3** Subdomains (it can run on 1 basically, but it will require knowhow how to run Keycloak on a subdomain and manual configuration)
* **sudo** or **root** rights on server

## What it does
We have developed a set of useful scripts to simplify the deployment of APProVe on a server. 
These scripts facilitate the creation of a .env file and the generation of NGINX configuration files. 
Following that, the install.sh script takes care of the APProVe installation and initiates its operation for you.


## Included Scripts
We offer three scripts, although only one of them is mandatory:

### generate_env.sh (optional)
This script takes the content from the ``.env.tmp`` file and transfers it into a new ``.env`` file. 
Subsequently, you can enter essential information about your APProVe instance, such as the Realm name and the domain on which APProVe will operate. 
The final step involves populating the newly generated ``.env`` file with your input.

### generate_nginx_conf (optional)
This script is designed to create NGINX configuration files based on the details in the ``.env`` file. 
Furthermore, it deposits these files in the ``/etc/nginx/sites-available`` directory and establishes symbolic links in 
the ``/etc/nginx/sites-enabled`` folder. It generates three files, one for each subdomain. Please note that you will need to 
provide the SSL certificates on your own. We highly recommend utilizing Certbot for this purpose, like so:
````shell
sudo certbot --nginx
````


### install.sh (mandatory)
This script carries out the installation of your APProVe instance in accordance with the information in your ``.env`` file. 
It also configures Keycloak with a Client as specified in your ``.env`` file. Furthermore, it adds an admin user to both APProVe 
and Keycloak. The default username and password for APProVe are as follows:

````shell
Username: approve-admin
Password: approve-password
````

The default username and password for Keycloak are as follows:

````shell
Username: adminuser
Password: adminpass
````

## Installing APProVe


