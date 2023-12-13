<div align="center">
  <h1>APProVe <sup>by iBDF</sup></h1>
</div>

APProVe is a software developed by the Interdisciplinary Biomaterials and Database Frankfurt (iBDF) for the convenient management of biosamples and clinical data in research projects. It provides researchers and iBDF employees with a clear means of handling and tracking project requests to the biobank, mapping the entire process from application submission to sample distribution and project completion.

[[_TOC_]]

<div align="center">
  <h4>A Project Proposal Management Software for Biobanks</h4>
</div>

<p align="center">
  <a href="#">
    <img src="https://gitlab.ibdf-frankfurt.de/uct/open-approve/-/raw/master/img/Project_management-APProVe_en.png" alt="Workflow" style="height: 120px; width: 120px">
  </a>
</p>

## System Requirements
- RAM: 6GB
- Multi-core processor (e.g., Intel i5)
- Hard disk space: 500 MB

## Features
APProVe is the first software to digitally and transparently map the application process and further follow-up of projects for all parties involved. The following functions have been integrated:

1. Online submission of project applications
2. User-related access/view of projects
3. Overview of all projects in which a user is involved
4. Tracking of the current project status
5. Email notification of project changes, project status, or new comments
6. Project-related communication via the comment function
7. Assignment of project-related to-dos for biobank members
8. Tabular summary of projects in tiles based on various criteria for a better overview

## Changelogs and Documentation
Each instance has its own Manual Service, containing useful information about managing and using APProVe, as well as the changelogs. If you don't have access to a running Manual Service, you can check the latest changelogs and documentation at: [Manual-Develop](https://backend.approved.ibdf-frankfurt.de/manual/updates/).

Please note that a few versions may be unreleased or still in testing and will be made public later.

## APProVe Installation
You can choose to install APProVe for testing purposes on a computer. For local installation, refer to this guide: [Local Setup](https://gitlab.ibdf-frankfurt.de/uct/open-approve/-/tree/master/complete-local-setup?ref_type=heads). If you want to install APProVe on a server environment with reverse proxying, use this guide instead: [Server Setup](https://gitlab.ibdf-frankfurt.de/uct/open-approve/-/tree/master/server-setup?ref_type=heads).

Further improvements will be based on feedback.

## Upgrade Guide

### 3.4 to 3.5
If you have previously run APProVe in Version 3.4 and want to upgrade to 3.5 you have to check for these breaking changes.

#### Mongo upgrade
Our GoLang Services (email, comment, automation) previously used the MongoDriver Version for MongoDB 4. As this approaches the end of support we chose to directly upgrade our services to be used by the new MongoDB 6 version.
If you want to upgrade APProVe from 3.4 to 3.5 you have to first download the new images for email-service (1.4.0), comment-service(1.1.0) and automation-service(1.5.0) and leave the MONGO_IMAGE at 4.4.

Afterward, increase the version from MONGO_IMAGE=mongo:4.4 to MONGO_IMAGE=mongo:5.0 in the ``.env``-file and run ``docker-compose pull`` again and run ``docker-compose up -d mongo``.

Now update the internal Mongo version with this command:

````shell
docker exec -ti approve.mongo bash -c "mongo -u mongo_admin -p mongopass --eval \"db.adminCommand( {setFeatureCompatibilityVersion: '5.0' } )\""
````

Now you can change the image version again to MONGO_IMAGE=mongo:6

Again update the internal Mongo version with this command (be careful mongo now uses mongosh)

````shell
docker exec -ti approve.mongo bash -c "mongo -u mongo_admin -p mongopass --eval \"db.adminCommand( {setFeatureCompatibilityVersion: '5.0' } )\""
````

docker exec -ti approve.mongo-demo bash -c "mongosh --port 27014 -u mongo_admin -p mongopass --eval \"db.adminCommand( {setFeatureCompatibilityVersion: '6.0' } )\""

Now you can start the new GoLang services with docker-compose up -d

#### Breaking change in email-service
email-Service version 1.4.0 introduces password encryption of the mail-server which was previously saved in the database.
Now every time you restart the email-service it generates an encryption_key to encrypt the password in the database. This means your password can't be decrypted after a restart of the service.
To persist the changes we introduced a new ``.env``-variable called ``ENCRYPTION_KEY``. When the new email-service starts it will generate one. just check the logs via ``docker logs mail-service`` or create the key via ``openssl rand -hex 32``.
Now place it in your ``.env``-file like this:
````yaml
ENCRYPTION_KEY=1911668690d83b2ded9176039111e15b568217d3e7be215f2a0a1ea5b82f8a27
````

Add this line to the ``docker-compose.yml``

``ENCRYPTION_KEY: ${ENCRYPTION_KEY}``
under mail-service -> environment.

it should look like this:

````yaml
  mail-service:
    #-------------------------------------------------------------------------------------
    # ==== Mainly CRUD service in golang for emails and templates ====
    #-------------------------------------------------------------------------------------
    restart: always
    image: ${EMAIL_IMAGE}
    container_name: approve.mails
    ports:
      - ${EMAIL_PORT}:4234
    environment:
     ...
      ENCRYPTION_KEY: ${ENCRYPTION_KEY}
    networks:
      - approve_network

````

After these changes you have to reconfigure your mail-service if you already had one in the settings of APProVe.



## Popular Documentation
For more information, visit our [iBDF Wiki](https://ibdf-frankfurt.de/wiki/Hauptseite).

## Contribution
[APProVe Architecture](https://backend.demo.ibdf-frankfurt.de/manual/introduction/architecture.html) consists of the following Microservices
1. [Manual](https://github.com/iBDFrankfurt/APProVe-Manual): Documentation of APProVe

## Credits
This software uses the following open-source packages:
- [Node.js](https://nodejs.org/)
- [moment.js](https://momentjs.com/)
- [jQuery.js](https://jquery.com/)
- [Bootstrap](https://getbootstrap.com/)
- [Keycloak](https://www.keycloak.org/about)

For installation guidance, please refer to the following links:
- [Docker Installation][docker]
- [Git Installation][git]

[docker]: <https://docs.docker.com/install>
[git]: <https://www.atlassian.com/git/tutorials/install-git>
