<div align="center">
  <b>APProVe</b>
  <br>
</div>
<br>
<br>

APProVe is a software developed by the Interdisciplinary Biomaterials and Database Frankfurt (iBDF) for easy application of biosamples and clinical data for research projects. It enables researchers and employees of the iBDF to clearly manage and track project requests to the biobank and maps the complete process from application submission to sample distribution and project completion. 

[[_TOC_]]

<div align="center">
<h4>A Project Proposal management Software for Biobanks.</h4>
</div>

<p align="center">
  <a href="#">
    <img src="https://gitlab.proskive.de/tschneider/APProVe-images/-/raw/master/img/workflow-proskive.png"
         alt="Gitter">
  </a>
</p>

## System Requirements
* RAM 4GB
* Multi-core processor (e.g. Intel i7)
* 500 MB hard disk space

## Funktionen

APProVe ist die erste Software, die den Beantragungsprozess und die weitere Nachverfolgung von Projekten für alle Beteiligte digital und transparent abbildet. Folgende Funktionen sind bisher integriert:
1.	online Einreichung von Projektanträgen
2.	Nutzbezogener Zugriff/Einsicht auf/von Projekte/n
3.	Übersicht über alle Projekte an denen ein Nutzer als Projektleiter oder Kooperationsleiter beteiligt ist
4.	Nachverfolgung des aktuellen Projektstatus
5.	Email-Benachrichtigung bei Änderungen am Projekt, Projektstatus oder neuen Kommentaren
6.	Projektbezogene Kommunikation über Kommentarfunktion
7.	Zuordnung von personen- und projektbezogenen to-dos für die Biobankmitarbeite


## How To Use

To run this application, you'll need [Docker](https://docker.com) installed on your computer. From your command line:

```bash
# 1. Clone this repository
$ git clone https://gitlab.proskive.de/tschneider/APProVe-images

# 2. Go into the repository
$ cd APProVe-images

# 3. Adjust .env file to your preferences
$ sudo nano .env

# 4. Run docker-compose
$ docker-compose up -d

# 4. Access the Frontend
$ http://localhost:$FRONTEND_PORT
```


## Configuration
APProVe is configured solely through environment variables.
Below is an example currently running on the demo server
```bash
#---------------------------------------------------------------------------------------------------------
# ==== External Images ====
KEYCLOAK_IMAGE=jboss/keycloak:11.0.0
MONGO_IMAGE=mongo:3.6
POSTGRES_IMAGE=postgres:9.6-alpine
# ==== APProVe Images ====
# If you want to update a specific Image, just replace them here in the .env
CONFIG_IMAGE=registry.gitlab.proskive.de/tschneider/APProVe-images/uct-config-service:1.2.0
EUREKA_IMAGE=registry.gitlab.proskive.de/tschneider/APProVe-images/uct-eureka-service:1.4.0
BACKEND_IMAGE=registry.gitlab.proskive.de/tschneider/APProVe-images/uct-backend-service:0.16.0
FRONTEND_IMAGE=registry.gitlab.proskive.de/tschneider/APProVe-images/uct-frontend-service:0.16.0
USER_IMAGE=registry.gitlab.proskive.de/tschneider/APProVe-images/uct-user-service:1.0.0
ARCHIVE_IMAGE=registry.gitlab.proskive.de/tschneider/APProVe-images/uct-archive-service:1.0.0
COMMENT_IMAGE=registry.gitlab.proskive.de/tschneider/APProVe-images/uct-comment-service:1.0
NOTIFICATION_IMAGE=registry.gitlab.proskive.de/tschneider/APProVe-images/uct-notification-service:0.9.1
DRAFT_IMAGE=registry.gitlab.proskive.de/tschneider/APProVe-images/uct-draft-service:0.5
AUTOMATIOM_IMAGE=registry.gitlab.proskive.de/tschneider/APProVe-images/uct-automation-service:1.0
GATEWAY_IMAGE=registry.gitlab.proskive.de/tschneider/APProVe-images/uct-gateway-service:0.0.1
MANUAL_IMAGE=registry.gitlab.proskive.de/tschneider/APProVe-images/uct-manual-service:latest

#---------------------------------------------------------------------------------------------------------
# ==== Postgres Variables ====
PROSKIVE_POSTGRES_USER=user
PROSKIVE_POSTGRES_PASSWORD=pa$$w0rd
# Create default database for keycloak
PROSKIVE_AUTH_DB=proskive_auth

#---------------------------------------------------------------------------------------------------------
# ==== Mongo Variables ====
PROSKIVE_MONGO_USER=user
PROSKIVE_MONGO_PASSWORD=pa$$w0rd
MONGO_URL=mongodb://proskive.mongo
#---------------------------------------------------------------------------------------------------------
# ==== Keycloak Variables ====
KEYCLOAK_REALM_NAME=YOUR-REALM-NAME
PROSKIVE_KEYCLOAK_ADMIN_USER=admin
PROSKIVE_KEYCLOAK_ADMIN_PASSWORD=adminpa$$
PROSKIVE_KEYCLOAK_URL=https://subdomain1.your-domain.com/auth

#---------------------------------------------------------------------------------------------------------
# ==== Frontend URL ====
# APProVe is best used with 3 subdomains. 
# One for Keycloak, one for the frontend and one for the API-Gateway.
PROSKIVE_SELF_URL=https://subdomain2.your-domain.com

#---------------------------------------------------------------------------------------------------------
# ==== Backend URL's ====
PROSKIVE_BACKEND_URL=https://subdomain3.your-domain.com/project/
PROSKIVE_NOTIFICATION_URL=https://subdomain3.your-domain.come/notification/
PROSKIVE_ARCHIVE_URL=https://subdomain3.your-domain.com/archive/
PROSKIVE_AUTOMATION_URL=https://subdomain3.your-domain.com/automation/
PROSKIVE_USER_URL=https://subdomain3.your-domain.com/user/
PROSKIVE_COMMENTS_URL=https://subdomain3.your-domain.com/comment/
PROSKIVE_DRAFT_URL=https://subdomain3.your-domain.com/draft/
PROSKIVE_MANUAL_URL=https://subdomain3.your-domain.com/manual/

#---------------------------------------------------------------------------------------------------------
# ==== Eureka Variables ====
EUREKA_URL=http://proskive.eureka:8761/eureka

#---------------------------------------------------------------------------------------------------------
# ==== User-Service Variables ====
# !this user needs to be created in keycloak!
KEYCLOAK_USER_NAME=service-user
KEYCLOAK_USER_PASSWORD=service-user-pass

#---------------------------------------------------------------------------------------------------------
# ==== ProSkive Ports ====
AUTH_PORT=8443
MONGO_PORT=27017
POSTGRES_PORT=5432
CONFIG_PORT=8888
BACKEND_PORT=8001
FRONTEND_PORT=8000
USER_PORT=9001
EUREKA_PORT=8761
ARCHIVE_PORT=8002
COMMENT_PORT=3234
NOTIFICATION_PORT=9000
DRAFT_PORT=3232
AUTOMATION_PORT=3233
GATEWAY_PORT=8762
MANUAL_PORT=8585
```

## Reverse Proxy
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
$ sudo nano proskive-frontend.conf

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
# 3. Change the server_name and the port in the proxy_pass to the previously configured $FRONTEND_PORT from the .env

# 4. Navigate to the sites-enabled folder from NGINX
$ cd /etc/nginx/sites-enabled/

5. Create a symbolic link
$ sudo ln -s ../sites-available/proskive-frontend.conf

6. Run Certbot to generate an encryption
$ sudo certbot --nginx -d subdomain2.your-domain.com

7. Restart NGINX
$ sudo systemctl restart nginx
```
That's it, the frontend should be available via https://subdomain2.your-domain.com!

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
# 3. Change the server_name and the port in the proxy_pass to the previously configured AUTH_PORT from the .env

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
An API gateway is used at the back end, so calls must be forwarded to the respective microservice. This changes the config file a bit.
```bash
# 1. Navigate to the NGINX folder 
$ cd /etc/nginx/sites-available/

# 2. Create the config for the frontend
$ sudo nano proskive.conf

# 2. Paste the following
server {
    server_name subdomain3.your-domain.com;
    proxy_set_header   X-Real-IP $remote_addr;
    proxy_set_header   X-Scheme $scheme;
    proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Proto $scheme;
    proxy_set_header   X-Forwarded-Port $server_port;
    proxy_set_header   Host $http_host;

    location /notification/ {
        proxy_pass http://localhost:8762/notification/;
    }

    location /archive/ {
        proxy_pass http://localhost:<GATEWAY_PORT>/archive/;
    }

    location /user/ {
        proxy_pass http://localhost:<GATEWAY_PORT>/user/;
    }

    location /project/ {
        proxy_pass http://localhost:<GATEWAY_PORT>/project/;
    }

    location /automation/ {
        proxy_pass http://localhost:<GATEWAY_PORT>/automation/;
    }

    location /comment/ {
        proxy_pass http://localhost:<GATEWAY_PORT>/comment/;
    }

    location /draft/ {
        proxy_pass http://localhost:<GATEWAY_PORT>/draft/;
    }
}
# 3. Change the server_name and the port in the proxy_pass to the previously configured GATEWAY_PORT from the .env

# 4. Navigate to the sites-enabled folder from NGINX
$ cd /etc/nginx/sites-enabled/

5. Create a symbolic link
$ sudo ln -s ../sites-available/proskive.conf

6. Run Certbot to generate an encryption
$ sudo certbot --nginx -d subdomain3.your-domain.com

7. Restart NGINX
$ sudo systemctl restart nginx
```

## Keycloak Configuration
Navigate to http://localhost:<AUTH_PORT> or https://subdomain1.your-domain.com
You can login with the PROSKIVE_KEYCLOAK_ADMIN_USER and PROSKIVE_KEYCLOAK_ADMIN_PASSWORD variables from the .env-file.
After that you should create a new Realm and set it to KEYCLOAK_REALM_NAME from the .env-file.
In case you do not know how to create a new Realm, Keycloak offers a great [documentation](https://www.keycloak.org/docs/latest/getting_started/index.html#creating-a-realm-and-a-user).
<br>
In the next step we must protect our frontend with keycloak. Therefore, we need to create a new Client. 
Name this new Client "ProSkive-Web". Afterwards set the Access Type to "public" and the Root Url to your frontend.
<br>
Example: <br>
Root Url: https://subdomain2.your-domain.com/ <br>
Valid Redirect URIs: "*"<br>
Web Origins: "+"<br>
It should look like this:
<p align="center">
  <a href="#">
    <img src="https://gitlab.proskive.de/tschneider/APProVe-images/-/raw/master/img/keycloak-client.png"
         alt="keycloak-client">
  </a>
</p>
In the next step we need to add one new client. Name this one "rest-client". You do not need to add anything else here.
Now you should add your first user! <br>
```bash
Go to Manage -> Users -> Add User and set a credential
```

Before you can finally login in APProVe you should add two roles as well. <br>

```bash
Go to Configure -> Roles -> Add Role
and add these two roles
ROLE_PROSKIVE_ADMIN
ROLE_PROSKIVE_USER

Go to Manage -> Users -> Edit User and add the ROLE_PROSKIVE_ADMIN via "Role Mappings"
```

The User-Service needs to be able to talk with Keycloak, so you must create a second user for this particular communication. <br>
The user must have the name "KEYCLOAK_USER_NAME" and password "KEYCLOAK_USER_PASSWORD" which were set in the .env-file.
<br>
This user needs a specific Client-Role -> realm-admin.
<p align="center">
  <a href="#">
    <img src="https://gitlab.proskive.de/tschneider/APProVe-images/-/raw/master/img/service-user.png"
         alt="service-user">
  </a>
</p>

After that you have successfully configured Keycloak and you can login with your ROLE_PROSKIVE_ADMIN User.

## Popular Documentation
For further information take a look at our [iBDF Wiki](https://ibdf-frankfurt.de/wiki/Hauptseite).

## Credits

This software uses the following open source packages:

- [Node.js](https://nodejs.org/)
- [moment.js](https://momentjs.com/)
- [jQuery.js](https://jquery.com/)
- [Bootstrap](https://getbootstrap.com/)
- [Keycloak](https://www.keycloak.org/about)
