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
* RAM 6GB
* Multi-core processor (e.g. Intel i5)
* 500 MB hard disk space
* NGINX
* SSL Certificate or Certbot


## What it does
We created a few helpful scripts that will ease the deployment of APProVe on a server. The scripts will help you fill create a .env file and generates NGINX config files.
Afterward, the install.sh script will install APProVe and starts it for you. Later you can basically just run 
````shell
docker-compose down
docker-compose up -d
````

## Scripts


## Installing APProVe
We created a script to help you guide through the installation. You can find it in this repository or under this link: https://gitlab.ibdf-frankfurt.de/uct/open-approve/-/blob/master/install.sh


