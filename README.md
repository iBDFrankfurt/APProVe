<div align="center">
  <h1>APProVe <sup>by iBDF</sup></h1>
  <strong>Version 4.0.0</strong>
</div>

APProVe (Application Project Proposal Management Software) is a microservice-based ecosystem developed by the
Interdisciplinary Biomaterials and Database Frankfurt (iBDF). It provides a digital workflow for managing biosample
requests and clinical data, tracking the entire lifecycle from application submission to sample distribution.

[[_TOC_]]

<p align="center">
  <a href="#">
    <img src="https://gitlab.ibdf-frankfurt.de/uct/open-approve/-/raw/master/img/Project_management-APProVe_en.png" alt="Workflow" style="height: 120px; width: 120px">
  </a>
</p>

---

## Access & Collaboration

**APProVe is a closed-source software ecosystem.**

The source code for individual microservices and the Docker image registries are **private**. Access is granted only via
invitation. Our goal is to foster direct collaboration with institutions and research groups interested in implementing
APProVe.

1. **Invitation Only:** You cannot download the source code or pull the Docker images without being explicitly
   authorized by the iBDF team.
2. **Contact Us:** If you are interested in using APProVe at your location or collaborating on the project, please
   contact us to discuss an invitation and access to the repositories.
3. **Support:** Once invited, you will receive the necessary credentials to use the installation guides provided below.

**Contact:** TBA

## System Requirements

The full APProVe ecosystem runs as a suite of microservices.

- **RAM:** 6 GB minimum (**16 GB recommended** for full stack performance)
- **CPU:** 4-8 cores (Intel i5/i7 or equivalent)
- **Disk Space:** 10 GB+ (SSD recommended)
- **Architecture:** Docker-ready (Linux, macOS, or Windows via WSL2/Git Bash)

## Architecture & Services

APProVe is built on a distributed microservice architecture. The **Project Service** (`uct-backend-service`) acts as
the central hub for project-related logic. All services register at Eureka and call each other by their Eureka name;
the Spring Boot services additionally load their configuration from the Config Service. This README is the central
overview of the ecosystem; the README of each service only describes its own place in it.

### Core Service Landscape

| Repository                   | Eureka name          | Port | Tech Stack                 | Purpose                                                                 |
|:-----------------------------|:---------------------|:-----|:---------------------------|:------------------------------------------------------------------------|
| **uct-config-service**       | –                    | 8888 | Spring Boot 3              | Central configuration (Spring Cloud Config, configs in Git submodule)   |
| **uct-eureka-service**       | –                    | 8761 | Spring Boot 3              | Service discovery and registration                                      |
| **uct-backend-service**      | `PROJECT-SERVICE`    | 8000 | Spring Boot 3              | Central API: projects, realms, master data, authorization (PostgreSQL)  |
| **uct-frontend-service**     | `PROJECT-WEB-SERVICE` | 8001 | Spring Boot 3 / Thymeleaf  | Delivers the UI and the Vue.js bundle, backend-for-frontend (BFF)       |
| **uct-vuejs-frontend**       | –                    | –    | Vue.js 2 / Webpack 5       | Vue components, built into `uct-frontend-service`                       |
| **uct-user-service**         | `USER-SERVICE`       | 9000 | Spring Boot 3              | Users, roles, groups and sessions via the Keycloak Admin API            |
| **uct-project-import-service** | `PROJECT-IMPORT-SERVICE` | 8003 | Spring Boot 3       | Import/export of project data (JSON, XML, CentraXX), API keys           |
| **uct-email-service**        | `MAIL-SERVICE`       | 4234 | Go                         | Mails, SMTP servers and templates (MongoDB)                             |
| **uct-comment-service**      | `COMMENT-SERVICE`    | 3234 | Go                         | Project comments (MongoDB)                                              |
| **uct-automation-service**   | `AUTOMATION-SERVICE` | 3233 | Go                         | Stores automation rules (MongoDB); the backend executes them            |
| **uct-manual-service**       | –                    | –    | VuePress 2                 | User manual, hosted with every installation                             |
| **Keycloak** (`auth`)        | –                    | –    | Keycloak 23 (Quarkus)      | Identity and access management (OIDC)                                   |
| **keycloak-event-listener**  | –                    | –    | Keycloak SPI (Java)        | Syncs users, roles and role mappings from Keycloak to the backend       |
| **keycloak-themes**          | –                    | –    | Keycloak theme             | APProVe login theme (`uct`)                                             |
| **proskive-dto**             | –                    | –    | Java library               | `approve-domain-dto`: backend entity classes used by the frontend service |

Infrastructure: PostgreSQL 16 (projects, users, Keycloak), MongoDB 7 (comments, automation, mails).

`uct-gateway-service` (Spring Cloud Gateway, port 8762) exists as a repository but is not part of the standard
deployment in `local-setup` / `server-setup`.

### Communication

- **uct-frontend-service** is the entry point for users. Server-side it mainly calls `PROJECT-SERVICE` and
  `USER-SERVICE` and relays the user's Keycloak token.
- The **Vue.js components** in the browser additionally call the Go services (comments, mails, automation) and other
  APIs directly via their public URLs, which the frontend service passes to the templates (e.g. `automation.url`).
- **uct-backend-service** calls `USER-SERVICE`, `MAIL-SERVICE` and `AUTOMATION-SERVICE` (e.g. to send mails and to
  execute automation rules).
- **uct-project-import-service** works on the same PostgreSQL database as the backend (it uses the backend as a
  library) and calls `USER-SERVICE`, `MAIL-SERVICE` and `AUTOMATION-SERVICE`.
- **Keycloak** pushes user and role changes to the backend via the **keycloak-event-listener**.
- All services validate requests against Keycloak.

See the diagrams in [`planning/`](planning/) and the
[architecture page of the manual](https://backend.demo.ibdf-frankfurt.de/manual/dev/architecture.html).

### Critical Startup Path

The ecosystem follows a strict initialization order to ensure service discovery:

1. **Infrastructure:** PostgreSQL, MongoDB, Keycloak
2. **Registry:** Config Service → Eureka Service
3. **Core API:** Project Service (Backend)
4. **Interface:** Frontend Service, User Service, Import Service, Go services, Manual

### Branches & Releases

- `uct-backend-service`, `uct-frontend-service`, `uct-vuejs-frontend`: development in version branches (`X.Y.Z`),
  merged into `develop` (test server), then `develop` → `master` after testing. Production uses `master` images only.
- `uct-project-import-service`, `uct-user-service`, `uct-eureka-service` and the Go services: `develop` (test) and
  `master` (production).
- All other repositories: `master` only.

## Installation Guides

Choose the setup that matches your environment:

### [Local Setup Guide](local-setup/README.md)

For developers and testing. Uses Docker Desktop and local `hosts` file entries to simulate the domain environment.

### [Server Setup Guide](server-setup/README.md)

For production environments. Includes Nginx Reverse Proxy configuration, SSL termination (Certbot), DNS requirements,
and automated backup strategies.

---

## Database Management

APProVe uses a dual-database approach:

- **PostgreSQL:** Primary storage for Projects, Users, and Keycloak data. Managed via **Flyway migrations** (
  V1.1__description.sql format).
- **MongoDB:** Specialized storage for high-frequency data like comments, automation logs, and email history.

## Documentation & API

- **Swagger UI:** Once the backend is running, explore the API at
  `http://approve.backend:8000/api/swagger-ui/index.html`.
- **Manual Service:** Each instance hosts its own documentation. The latest updates are available
  at [Manual-Develop](https://backend.demo.ibdf-frankfurt.de/manual/).
- **Internal Wiki:** [iBDF Wiki](https://ibdf-frankfurt.de/wiki/Hauptseite)

## Legacy Upgrade (3.x to 4.x)

<details>
<summary>Click for breaking changes (Mongo/Email encryption)</summary>

### MongoDB Migration

Upgrading to 4.x requires a sequential migration of MongoDB features:

```bash
# Set compatibility to 5.0
docker exec -ti approve.mongo bash -c "mongosh -u mongo_admin -p mongopass --eval \"db.adminCommand( {setFeatureCompatibilityVersion: '5.0' } )\""
# Then repeat for 6.0
```

### Email Service Encryption

Starting with v1.4.0, the email service requires a 32-byte hex `ENCRYPTION_KEY` in the `.env` file to protect mail-server
credentials stored in the database.

```bash
openssl rand -hex 32
```

</details>

## Credits

This software uses open-source packages including Spring Boot, Keycloak, GoLang, Flyway, and Vue.js. For full dependency
details, check individual service `pom.xml` files.

---
**Managed by the Interdisciplinary Biomaterials and Database Frankfurt (iBDF).**
