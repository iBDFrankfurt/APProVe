[TOC]

# Keycloak Event Listener

- Version: 1
- Java Version: 11

Keycloak is designed to cover most use-cases without requiring custom code, but it is very customizable. 
To achieve this Keycloak has a number of Service Provider Interfaces (SPI) for which you can implement your own providers.
This SPI is responsible to communicate with the uct-project-service of APProVe whenever the following event is logged in Keycloak:
- Login of user
- Create user
- Update user
- Delete user
- Create role
- Update role
- Delete role

[Read More](https://www.keycloak.org/docs/latest/server_development/#_providers)


# Depending On
- Keycloak

# Used By.
- [ ] uct-eureka-service
- [ ] uct-frontend-service
- [x] uct-project-service
- [ ] uct-draft-service
- [ ] uct-project-import-service
- [ ] uct-user-service
- [ ] uct-manual-service
- [ ] uct-email-service
- [ ] uct-automation-service
- [ ] uct-comment-service
- [ ] VueJs-frontend

# How to run

```shell
$ mvn package
```

# How to use

1. When deploying clone from gitlab

````shell
git clone https://gitlab.proskive.de/uct/keycloak-event-listener
````

2. Has to be added as a Volume for Keycloak

```shell
volumes:
- "./keycloak-event-listener/target/:/opt/jboss/keycloak/standalone/deployments/"
```

# Contributing
Before contributing please read the official documentation listed above!

## KeycloakEventListenerProviderFactory.class
Implements ``EventListenerProviderFactory.class`` and registers the ``KeycloakEventListenerProvider.class``.

## KeycloakEventListenerProvider.class
Overrides the onEvent Method from ``EventListenerProvider.class`` to log events in Keycloak. Put your logic in here, if you want to
check for additional events happening in Keycloak.

# Environment Variables

| Name                	| Description                                                                                                                      	|
|---------------------	|----------------------------------------------------------------------------------------------------------------------------------	|
| REST_USER           	| Same user as defined in the .env File. Acts as realm_admin user with access to users/realms/roles in Keycloak                    	|
| REST_PASSWORD       	| Password for rest user above                                                                                                     	|
| CLIENT_ID           	| The Res_User has to be defined as a Keycloak client, this can be the same client that secures APPrOve or an additional one       	|
| GRANT_TYPE          	| As of now only password is acceptable                                                                                            	|
| KEYCLOAK_URL        	| URL of Keycloak to receive data from. As of now it is not possible to get users internally via SPI from Keycloak, so we use REST 	|
| BACKEND_SERVICE_URL 	| URL of uct-project-service                                                                                                       	|
| KEYCLOAK_REALM      	| Realm of Keycloak to receive the users from                                                                                      	|

You can place them in the docker-compose.yml under services.auth.environment.

For example:
````yaml
auth:
    restart: always
    container_name: approve.auth
    image: ${KEYCLOAK_IMAGE}
    ports:
      - 8080:8080
    environment:
      ...
      REST_USER: restuser
      REST_PASSWORD: restuser
      CLIENT_ID: rest-client
      GRANT_TYPE: password
      KEYCLOAK_REALM: UCT
      KEYCLOAK_URL: ${APPROVE_KEYCLOAK_URL}
      BACKEND_SERVICE_URL: ${APPROVE_BACKEND_URL}

````
