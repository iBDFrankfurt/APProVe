<div align="center">
  <b>APProVe <sup>by iBDF</sup></b>
  <br>
</div>
<br>
<br>

APProVe is a software developed by the Interdisciplinary Biomaterials and Database Frankfurt (iBDF) for easy application of biosamples and clinical data for research projects. It enables researchers and employees of the iBDF to clearly manage and track project requests to the biobank and maps the complete process from application submission to sample distribution and project completion. 

[[_TOC_]]

<div align="center">
<h4>A Project Proposal management Software for Biobanks</h4>
</div>

<p align="center">
  <a href="#">
    <img src="https://gitlab.ibdf-frankfurt.de/uct/open-approve/-/raw/master/img/Project_management-APProVe_en.png" alt="WorkFlow" style="height: 120px; width: 120px">
  </a>
</p>

## System Requirements
* RAM 6GB
* Multi-core processor (e.g. Intel i5)
* 500 MB hard disk space

## Features

APProVe is the first software to digitally and transparently map the application process and further follow-up of projects for all parties involved. The following functions have been integrated so far:

1. online submission of project applications
2. user-related access/view of project(s)
3. overview of all projects in which a user is involved
4. tracking of current project status
5. email notification of project changes, project status or new comments
6. project-related communication via comment function
7. assignment of project-related to-dos for the biobank members
8. Tabular summary of projects in tiles based on various criteria for a better overview

## Changelogs and Documentation
Every Instance gets their own Manual-Service. Not only does it contain useful information about managing and using APProVe, it also contains the changelogs.
If you have no running Manual-Service you can check the newest changelogs and documentation at: [Manual-Develop](https://backend.approved.ibdf-frankfurt.de/manual/updates/)

Please keep in mind, that a few versions are unreleased or still being tested and made public later.

## Installing APProVe
We created a script to help you guide through the installation. You can find it in this repository or under this link: https://gitlab.ibdf-frankfurt.de/uct/open-approve/-/blob/master/install.sh
The script will deploy it locally, if you want to deploy it on a server you have to adjust the .env **before** running the install.sh script.
!!IMPORTANT: Please run before running the install.sh script!!

```bash
docker login registry.gitlab.ibdf-frankfurt.de
````

### The script will do the following things:
1. Check if docker, docker-compose and git are installed
2. Checks if the .env file is present
3. Login to the registry for APProVe Images
4. Downloads the custom made themes for keycloak from https://gitlab.ibdf-frankfurt.de/proskive/keycloak-themes.git
5. Downloads the custom made keycloak-event-listener to update the database of APProVe https://gitlab.ibdf-frankfurt.de/uct/keycloak-event-listener.git
6. Creates the APProVe Docker Network and pulls the latest versions
7. Starts all services
8. After the services started it will begin to configure Keycloak based on the provides .env file
9. Create new realm 
10. Creates user to communicate between APProVe and Keycloak 
11. Sets the previously downloaded keycloak-event-listener to this realm 
12. Creates a client in Keycloak 
13. Creates a default admin role 
14. Creates an admin user with that admin role 
15. Checks if the role and admin user were created in APProVe

### What the script is NOT doing:
1. Does not add entries to the hosts file if run locally
2. Does not add configurations for reverse proxy in a server environment
3. Sets the URL's to reach every service

## Local Deployment
For a local deployment either check https://gitlab.ibdf-frankfurt.de/uct/open-approve/-/tree/master/complete-local-setup or https://gitlab.ibdf-frankfurt.de/uct/open-approve/-/tree/master/minimal-local-setup.

## Server Installation
If you want to deploy APProVe in a Server environment you need to add a reverse proxy. For this guide we will demonstrate it with NGINX.

### Reverse Proxy
To be accessible from the outside world, a domain and at least 3 subdomains are required.
This guide explains the steps using [NGINX](https://www.nginx.com/) and [Certbot](https://certbot.eff.org/) to encrypt APProVe with SSL and to set up a reverse proxy to
make the docker containers accessible.

<p>For this we look at 3 NGINX configuration files.
For the frontend, for Keycloak and for the backend.</p>

### Frontend NGINX Config
Let's start with the frontend.
```bash
# 1. Navigate to the NGINX folder 
$ cd /etc/nginx/sites-available/

# 2. Create the config for the frontend
$ sudo nano approve-frontend.conf

# 2. Paste the following
server {
    server_name subdomain2.your-domain.com;
    proxy_set_header   X-Real-IP $remote_addr;
    proxy_set_header   X-Scheme $scheme;
    proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Proto $scheme;
    proxy_set_header   X-Forwarded-Port $server_port;
    proxy_set_header   Host $http_host;

    location / {
        proxy_pass http://localhost:<FRONTEND_PORT>;
    }
}
# 3. Change the server_name and the port in the proxy_pass to the previously configured $FRONTEND_PORT from the .env.tmp

# 4. Navigate to the sites-enabled folder from NGINX
$ cd /etc/nginx/sites-enabled/

5. Create a symbolic link
$ sudo ln -s ../sites-available/approve-frontend.conf

6. Run Certbot to generate an encryption
$ sudo certbot --nginx -d subdomain2.your-domain.com

7. Restart NGINX
$ sudo systemctl restart nginx
```
That's it, the frontend should be available via https://subdomain2.your-domain.com

### Keycloak NGINX Config
It is basically the same procedure.
```bash
# 1. Navigate to the NGINX folder 
$ cd /etc/nginx/sites-available/

# 2. Create the config for the frontend
$ sudo nano keycloak.conf

# 2. Paste the following
server {
    server_name subdomain1.your-domain.com;
    proxy_set_header   X-Real-IP $remote_addr;
    proxy_set_header   X-Scheme $scheme;
    proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Proto $scheme;
    proxy_set_header   X-Forwarded-Port $server_port;
    proxy_set_header   Host $http_host;

    location / {
        proxy_pass http://localhost:<AUTH_PORT>;
    }
}
# 3. Change the server_name and the port in the proxy_pass to the previously configured AUTH_PORT from the .env.tmp

# 4. Navigate to the sites-enabled folder from NGINX
$ cd /etc/nginx/sites-enabled/

5. Create a symbolic link
$ sudo ln -s ../sites-available/keycloak.conf

6. Run Certbot to generate an encryption
$ sudo certbot --nginx -d subdomain1.your-domain.com

7. Restart NGINX
$ sudo systemctl restart nginx
```

### Backend NGINX Config
In the following we wil use the standard ports. If you changed them in the .env-File you have to change them here accordingly.
```bash
# 1. Navigate to the NGINX folder 
$ cd /etc/nginx/sites-available/

# 2. Create the config for the frontend
$ sudo nano approve.conf

# 2. Paste the following
server {
    server_name subdomain3.your-domain.com;
    proxy_set_header   X-Real-IP $remote_addr;
    proxy_set_header   X-Scheme $scheme;
    proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Proto $scheme;
    proxy_set_header   X-Forwarded-Port $server_port;
    proxy_set_header   Host $http_host;

  location / {
    proxy_pass http://localhost:8000;
    }

  location /user-service/ {
     proxy_pass http://localhost:9001/;
    }

  location /automation-service/ {
    proxy_pass http://localhost:3233/;
  }

  location /comment-service/ {
    proxy_pass http://localhost:3234/;
  }
  location /mail-service/ {
    proxy_pass http://localhost:4234/;
  }
  location /eureka-service/ {
    proxy_pass http://localhost:8761/;
  }
  location /draft-service/ {
    proxy_pass http://localhost:8002/;
  }
  location /manual/ {
    proxy_pass http://localhost:443/manual/;
  }

}

# 3. Change the server_name and the port in the proxy_pass to the previously configured ports from the .env.tmp

# 4. Navigate to the sites-enabled folder from NGINX
$ cd /etc/nginx/sites-enabled/

5. Create a symbolic link
$ sudo ln -s ../sites-available/approve.conf

6. Run Certbot to generate an encryption
$ sudo certbot --nginx -d subdomain3.your-domain.com

7. Restart NGINX
$ sudo systemctl restart nginx
```


## Popular Documentation
For further information take a look at our [iBDF Wiki](https://ibdf-frankfurt.de/wiki/Hauptseite).

## Credits

This software uses the following open source packages:

- [Node.js](https://nodejs.org/)
- [moment.js](https://momentjs.com/)
- [jQuery.js](https://jquery.com/)
- [Bootstrap](https://getbootstrap.com/)
- [Keycloak](https://www.keycloak.org/about)

[docker]: <https://docs.docker.com/install>
[git]: <https://www.atlassian.com/git/tutorials/install-git>
