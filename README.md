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
    <img src="https://gitlab.proskive.de/uct/open-approve/-/raw/master/img/Project_management-APProVe_en.png" alt="WorkFlow" style="height: 120px; width: 120px">
  </a>
</p>

## System Requirements
* RAM 6GB
* Multi-core processor (e.g. Intel i5)
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


## Starting APProVe

* [Install Docker][docker] and [git][git] and test with:

```sh
docker run hello-world
git --version
```

* Clone this repository
```sh
$ git clone https://gitlab.proskive.de/uct/open-approve.git
```

* Go into the repository
```sh
$ cd open-approve
```

* Copy the example and adjust .env file to your preferences
Click [here](#configuration) to view how.
```sh
$ cp .env-example .env
$ nano .env
```

* Clone the Keycloak SPI keycloak-event-listener
```sh
$ git clone https://gitlab.proskive.de/uct/keycloak-event-listener.git
```

* Mount it as volume for Keycloak

Click [here](#keycloak-service-provider-interface) to view more.

* Configure Reverse Proxy

Click [here](#reverse-proxy) for an example in NGINX

* To configure Keycloak we need to create a network then start the postgres and auth container. Postgres should be started first, so that Keycloak can connect to it.
```sh
$ docker network create approve_network
$ docker-compose up -d postgres
Check if there are any errors
$ docker logs approve.postgres

$ docker-compose up -d auth
Check if there are any errors
$ docker logs approve.auth
Check the line >>Deployed "keycloak-event-listener.jar" (runtime-name : "keycloak-event-listener.jar")<<, if it doesn't exist check for the error 
```

Click [here](#keycloak-configuration) for a detailed explanation.

* When you first run APProVe it is advised to start every service after another to check if a service runs properly. If you want to quickly deploy APProVe you can skip these.

1. Config-Service stores all config files for the spring-boot services and acts as a centralized config hub. so it should be started before all other spring-boot services
```sh
$ docker-compose up -d config-service
$ docker logs approve.config
```

2. Eureka-Service acts as a registration for every service. It allows communication between each service and can store stats about those.
```sh
$ docker-compose up -d eureka-service
$ docker logs approve.eureka
```

3. Backend-Service stores all project related data and migrates the database to the postgres service
```sh
$ docker-compose up -d backend-service
$ docker logs approve.backend
```
You should see in the backend-service logs that the migration of the database started.

4. User-Service acts as a middle man between the frontend and keycloak
```sh
$ docker-compose up -d user-service
$ docker logs approve.user
```

5. Frontend-Service acts as the frontend of APProVe 
```sh
$ docker-compose up -d frontend-service
$ docker logs approve.frontend
```

6. Gateway-Service is optional and connects itself to eureka to receive all registered service endpoints 
```sh
$ docker-compose up -d gateway-service
$ docker logs approve.gateway
```

7. Mongo Service acts as a non-releational database to save comments/emails/email-templates and automation rules
```sh
$ docker-compose up -d mongo
$ docker logs approve.mongo
```

8. Comment-Service will save/update/delete all comments in all projects
```sh
$ docker-compose up -d comments-service
$ docker logs approve.comment
```

9. Email-Service will save/update/delete all emails and email templates and send emails. You need to connect a mail-server yourself
```sh
$ docker-compose up -d mail-service
$ docker logs approve.mails
```

10. Automation-Service will save/update/delete automation rules. These rules can be very complex, please read the APProVe Manual
```sh
$ docker-compose up -d automation-service
$ docker logs approve.automation
```

10. Manual-Service will start a manual you can consult before using APProVe
```sh
$ docker-compose up -d manual-service
$ docker logs approve.manual
```


* If you want to start all services parallel...
```sh
$ docker-compose up -d
```

* Add your admin user

Check [here](#add-admin-user-approve).

* First test the installation: check to see if there is a frontend running on $FRONTEND_PORT:
```sh
$ curl localhost:$FRONTEND_PORT | grep APProVe
```

* If you need to stop APProVe, from within the directory with the docker-compose.yml:
```sh
$ docker-compose down
```

## Configuration
APProVe is configured through environment variables.
Below is an example how it could look.
```bash
#---------------------------------------------------------------------------------------------------------
# ==== External Images ====
KEYCLOAK_IMAGE=jboss/keycloak:14.0.0
MONGO_IMAGE=mongo:3.6
POSTGRES_IMAGE=postgres:12.7-alpine
# ==== ProSkive-Bio Images ====
CONFIG_IMAGE=registry.gitlab.proskive.de/uct/open-approve/uct-config-service:1.0.0
EUREKA_IMAGE=registry.gitlab.proskive.de/uct/open-approve/uct-eureka-service:1.5.0
BACKEND_IMAGE=registry.gitlab.proskive.de/uct/open-approve/uct-backend-service:2.0.0
FRONTEND_IMAGE=registry.gitlab.proskive.de/uct/open-approve/uct-frontend-service:2.0.0
USER_IMAGE=registry.gitlab.proskive.de/uct/open-approve/uct-user-service:1.1.0
COMMENT_IMAGE=registry.gitlab.proskive.de/uct/open-approve/uct-comment-service:1.0.0
NOTIFICATION_IMAGE=registry.gitlab.proskive.de/uct/open-approve/uct-email-service:1.0.0
AUTOMATIOM_IMAGE=registry.gitlab.proskive.de/uct/open-approve/uct-automation-service:1.0.0
GATEWAY_IMAGE=registry.gitlab.proskive.de/uct/open-approve/uct-gateway-service:1.0.0
MANUAL_IMAGE=registry.gitlab.proskive.de/uct/open-approve/uct-manual-service:latest

#---------------------------------------------------------------------------------------------------------
# ==== Postgres Variables ====
# The postgres database will save all project related objects
PROSKIVE_POSTGRES_USER=<username postgres>
PROSKIVE_POSTGRES_PASSWORD=<passwort postgres>
# Create default database for keycloak
PROSKIVE_AUTH_DB=approve_auth

#---------------------------------------------------------------------------------------------------------
# ==== Mongo Variables ====
# Mongo saves all settings/emails/comments
PROSKIVE_MONGO_USER=<username mongo>
PROSKIVE_MONGO_PASSWORD=<password mongo>
# We need the container name to connect to other containers in the same network. if you change the container.name, change it here accordingly
MONGO_URL=mongodb://approve.mongo

#---------------------------------------------------------------------------------------------------------
# ==== Keycloak Variables ====
# Keycloak works with realms, so create a realm first in keycloak and enter its name here
KEYCLOAK_REALM_NAME=<your realm name>
PROSKIVE_KEYCLOAK_ADMIN_USER=<keycloak admin username>
PROSKIVE_KEYCLOAK_ADMIN_PASSWORD=<keycloak admin password>
PROSKIVE_KEYCLOAK_URL=https://auth.demo.proskive.de/auth

#---------------------------------------------------------------------------------------------------------
# ==== Frontend URL ====
# In manuals or mails there will be a reference to the frontend
PROSKIVE_SELF_URL=https://demo.proskive.de

#---------------------------------------------------------------------------------------------------------
# ==== Backend URL's ====
# The Frontend needs to call other services not only via eureka.
# These URL's have to match your nginx routing!
APPROVE_BACKEND_URL=https://backend.demo.proskive.de
APPROVE_AUTOMATION_URL=https://backend.demo.proskive.de/automation
APPROVE_USER_URL=https://backend.demo.proskive.de/user
APPROVE_COMMENTS_URL=https://backend.demo.proskive.de/comment
APPROVE_MANUAL_URL=https://backend.demo.proskive.de/manual
APPROVE_MAIL_URL=https://backend.demo.proskive.de/mail

#---------------------------------------------------------------------------------------------------------
# ==== Eureka Variables ====
EUREKA_URL=http://approve.eureka:8761/eureka

#---------------------------------------------------------------------------------------------------------
# ==== User-Service Variables ====
# !this user needs to be created in keycloak!
# please read further down below in the Keycloak Configuration section
KEYCLOAK_USER_NAME=<special user name>
KEYCLOAK_USER_PASSWORD=<special user password>

#---------------------------------------------------------------------------------------------------------
# ==== APProVe Ports ====
AUTH_PORT=8443
MONGO_PORT=27017
POSTGRES_PORT=5432
CONFIG_PORT=8888
BACKEND_PORT=8000
FRONTEND_PORT=8001
USER_PORT=9001
EUREKA_PORT=8761
COMMENT_PORT=3234
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
You have two options for your config. APProVe has the ability to use a gateway service called Zuul.
In case you don't know which one to use, you can use this routing example without the gateway service.
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

    location / {
    proxy_pass http://localhost:8000;
    }

  location /user/ {
     proxy_pass http://localhost:9001/;
    }

  location /automation/ {
    proxy_pass http://localhost:3233/;
  }

  location /comment/ {
    proxy_pass http://localhost:3234/;
  }
  location /mail/ {
    proxy_pass http://localhost:4234/;
  }
  location /eureka/ {
    proxy_pass http://localhost:8761/;
  }

  location /manual/ {
    proxy_pass http://localhost:8585/manual/;
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

When using a gateway service, the location paths are different. Please keep in mind, that the gateway is still beeing tested. 

```bash
# 1. Navigate to the NGINX folder 
$ cd /etc/nginx/sites-available/

# 2. Create the config for the frontend
$ sudo nano proskive.conf

# 2. Paste the following
server {
    server_name gate.cbbmr.proskive.de;
    proxy_set_header   X-Real-IP $remote_addr;
    proxy_set_header   X-Scheme $scheme;
    proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Proto $scheme;
    proxy_set_header   X-Forwarded-Port $server_port;
    proxy_set_header   Host $http_host;

    location /manual/ {
        proxy_pass http://localhost:8585/manual/;
    }
    location /mail {
        proxy_pass http://localhost:8762/mail/;
    }

    location /user/ {
        proxy_pass http://localhost:8762/user/;
    }

    location /project {
        proxy_pass http://localhost:8762/project/;
    }

    location /automation {
        proxy_pass http://localhost:8762/automation/;
    }

    location /comment {
        proxy_pass http://localhost:8762/comment/;
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
AS you can see, instead of calling the local address of each service, you call the gateway service that will do the routing for you.

## Keycloak Configuration
Navigate to http://localhost:<AUTH_PORT> or https://subdomain1.your-domain.com
You can login with the APPROVE_KEYCLOAK_ADMIN_USER and APPROVE_KEYCLOAK_ADMIN_PASSWORD variables from the .env-file.
After that you should create a new Realm and set it to KEYCLOAK_REALM_NAME from the .env-file.
In case you do not know how to create a new Realm, Keycloak offers a great [documentation](https://www.keycloak.org/docs/latest/getting_started/index.html#creating-a-realm-and-a-user).
<br>
In the next step we must protect our frontend with keycloak. Therefore, we need to create a new Client. 
Name this new Client how you want. Afterwards set the Access Type to "public" and the Root Url to your frontend.
<br>
Example: <br>
Root Url: https://subdomain2.your-domain.com/ <br>
Valid Redirect URIs: "*"<br>
Web Origins: "+"<br>
It should look like this:
<p align="center">
  <a href="#">
    <img src="https://gitlab.proskive.de/uct/open-approve/-/raw/master/img/keycloak-client.png"
         alt="keycloak-client">
  </a>
</p>
In the next step we need to add one new client. Name this one "rest-client". You do not need to add anything else here.

## Add Admin User APProVe
Before you add your first user be sure to check the followin:
1. Auth-Service needs to be up and running
2. Auth-Service Keycloak SPI should be linked and mounted
3. Backend-Service shoudl be up and running

If you add a new user in Keycloak, this user will automatically be saved in APProVe if the above statements are true.

```bash
Go to Manage -> Users -> Add User and set a credential
```

Before you can login in APProVe this user needs to have a role, so you should add the admin role. <br>
**With the addition of providing custom roles in this and future updates, this step can be ignored in the near future, but for now you should add at least the ROLE_PROSKIVE_ADMIN role.**

```bash
Go to Configure -> Roles -> Add Role
and add this role
ROLE_PROSKIVE_ADMIN
Under Attributes set the variables
is_admin true
can_edit true

Go to Manage -> Users -> Edit User and add the ROLE_PROSKIVE_ADMIN via "Role Mappings"

If you want to create a non admin role, just change the variables accordingly (i.e is_admin false)
```

<p align="center">
  <a href="#">
    <img src="https://gitlab.proskive.de/uct/open-approve/-/raw/master/img/admin_roles.png"
         alt="WorkFlow">
  </a>
</p>

The User-Service needs to be able to talk with Keycloak, so you must create a second user for this particular communication. <br>
The user must have the name "KEYCLOAK_USER_NAME" and password "KEYCLOAK_USER_PASSWORD" which you set in the .env-file.
<br>
This user needs a specific Client-Role -> realm-admin.
<p align="center">
  <a href="#">
    <img src="https://gitlab.proskive.de/uct/open-approve/-/raw/master/img/service-user.png"
         alt="service-user">
  </a>
</p>

## Keycloak Service Provider Interface
Keycloak can be extended using custom code. To achieve this Keycloak has a number of Service Provider Interfaces (SPI) for which we can implement our own providers. APProVe has such a provider. It offers the possibility to create users or roles in Keycloak, which are automatically saved or updated in APProVe afterwards. The complete user and role management is thus controlled via Keycloak.
In the future, we will provide our own keycloak image prebuilt with this spi, so that these steps become redundant.

To use this functionality please check the following steps:
```bash
1. move to your docker-compose.yml location 
2. git clone https://gitlab.proskive.de/uct/keycloak-event-listener.git
3. nano docker-compose.yml
4. add volumes to auth in docker-compose.yml
volumes:
  - "/your/location/keycloak-event-listener/target/:/opt/jboss/keycloak/standalone/deployments/"
this will add the keycloak service in your keycloak instance
5. For keycloak to have access to this SPI the folder needs read, write and execute permissions chmod -R 777 keycloak-event-listener/
6. docker-compose down && docker-compose up -d

To activate the spi, you need to enable it via the keycloak admin panel
1. Login as admin in keycloak
2. Navigate in the left Menu to Manage --> Events --> Click on Config and add "sample_event_listener" to Event Listeners
3. Scroll down and click save

To test if it has worked, add a new Role/User in Keycloak and check in the administration of APProVe if the role/user is present. For further information please check our manual which is installed via the docker-compose.yaml

```
<p align="center">
  <a href="#">
    <img src="https://gitlab.proskive.de/uct/open-approve/-/raw/master/img/add-keycloak-spi.png"
         alt="service-user">
  </a>
</p>

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
