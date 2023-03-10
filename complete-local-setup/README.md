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
    <img src="https://gitlab.proskive.de/uct/open-approve/-/raw/master/img/Project_management-APProVe_en.png" alt="WorkFlow" style="height: 120px; width: 120px">
  </a>
</p>

## System Requirements
* RAM 6GB
* Multi-core processor (e.g. Intel i5)
* 500 MB hard disk space

## What it does
Creating a basic deployment with needed services (user and manual is optional, but for the sake of not printing to many errors i added them).
It will also create a Realm ``test`` in Keycloak and add the Keycloak SPI automatically.


## Instructions
Clone this folder. Your folder should consist of
1. keycloak-event-listener
2. .env
3. docker-compose.yml
4. test-realm.json

### Login to registry

```sh
$ docker login registry.gitlab.proskive.de
```

### Pull Images from Repo

```sh
$ docker-compose pull
```

### Start Images

```sh
$ docker-compose up -d
```
On windows postgres sometimes prints errors. You should be able to ignore it until postgres finished. In the
meantime the backend may print errors as well with no connection possible to postgres. This will be handled automatically, it is enough to wait some time.


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
After that we can use the container_name in APProVe as localhost.

### Setup Keycloak
Type in your Browser
```
http://localhost:8080
```
Which should open Keycloak. You can login with the credentials from the .env-file
```
APPROVE_KEYCLOAK_ADMIN_USER=adminuser
APPROVE_KEYCLOAK_ADMIN_PASSWORD=adminpass
```

After successfully login in, you can create a new Realm and import the 
```
test-realm.json
```
This creates a new Realm ``test`` with the Client already configured and the event listener deployed automatically.

### Add rest user in Keycloak
Create a new User that handles communication with the backend and Keycloak named
``restuser``. This is the same user as in the ``.env-file``
```
KEYCLOAK_USER_NAME=restuser
KEYCLOAK_USER_PASSWORD=restuser_pass
```
Do not forget to set his credentials as well.

Next, assign a specific role for this user. This user should be able to call all users, realms, groups and roles. So
you can head over to the ``Role mapping`` in the user details of the ``restuser`` and assign the role ``realm-management realm-admin``.

After that the backend and Keycloak can communicate.

<figure>
  <div>
    <label for="role-mapping">
    <img id="role-mapping" src="https://gitlab.proskive.de/uct/open-approve/-/raw/master/img/keycloak/role-mapping.png" alt="Role mappings of user">
    </label>
      <figcaption>Role mappings of user overview</figcaption>
  </div>
</figure>

<figure>
  <div>
    <label for="role-mapping">
    <img id="role-mapping" src="https://gitlab.proskive.de/uct/open-approve/-/raw/master/img/keycloak/role-mapping2.png" alt="Role mappings of user">
    </label>
      <figcaption>Role mappings of user</figcaption>
  </div>
</figure>

<figure>
  <div>
    <label for="role-mapping">
    <img id="role-mapping" src="https://gitlab.proskive.de/uct/open-approve/-/raw/master/img/keycloak/role-mapping3.png" alt="Role mappings of user">
    </label>
      <figcaption>Role mappings of user</figcaption>
  </div>
</figure>

### Add Admin Role in Keycloak for APProVe
We need to add an admin user for APProVe. Head over to the ``Realm roles`` first in Keycloak and add a new Role.
This role will be our Admin Role. Name it whatever you like. The important part are the Attributes.
If you created a new Role you can open the Role details and head over to ``Attributes``.
Add the following:
````
Key: is_admin
Value: true
````
and hit save.

If you imported the ``test-realm.json`` file you can see an example role named ``APPROVE_ADMIN``.

### Add Admin User in Keycloak for APProVe
Head over to ``Users`` again and add a new user. Please add an email as well, as this is a required field in APProVe but not in Keycloak.
Do not forget to set credentials as well!
After creating the user you can add him to our Admin Role which we created in the step before.

### Login
After creating you Admin user the backend should already have the information send by Keycloak, so you can type in to your Browser
```
http://localhost:8001
```
And click in ``Anmelden``. You should be redirected to Keycloak and be able to login with your APProVe admin user.
After login you should be at the ``APProVe Dashboard`` with an orange layout indicating you are an admin.

## Notes
After we created the Restuser every create/update/delete event in Keycloak will trigger an event in APProVe.
You can check your logs if your admin user was created in APProVe by checking the approve.backend logs via
```sh
$ docker logs approve.backend -f
```

## Limitations
Currently, i was not able to change the Keycloak URl to a different port, so 8080 should be free before a local 
deployment.
Using the hosts file to imitate localhost calls will be fixed in the future.

