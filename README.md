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

APProVe is built on a distributed microservice architecture. The **Project Service** (Backend) acts as the central hub
for project-related logic.

### Core Service Landscape

| Service                    | Tech Stack             | Purpose                                          |
|:---------------------------|:-----------------------|:-------------------------------------------------|
| **uct-project-service**    | Spring Boot 3          | Central API / Project management hub             |
| **uct-frontend-service**   | Spring Boot 3 / Vue.js | UI Delivery and Backend-for-Frontend (BFF)       |
| **uct-config-service**     | Spring Boot 3          | Centralized configuration management             |
| **uct-eureka-service**     | Spring Boot 3          | Service discovery and registration               |
| **uct-auth (Keycloak)**    | Quarkus                | Identity and Access Management (OIDC)            |
| **uct-user-service**       | Spring Boot 3          | User profile and permission management           |
| **uct-email-service**      | GoLang                 | SMTP handling and template encryption            |
| **uct-comment-service**    | GoLang                 | Project discussions                              |
| **uct-automation-service** | GoLang                 | Automated status transitions and project updates |
| **uct-import-service**     | Spring Boot 3          | API Key Generation and Access                    |
| **uct-manual-service**     | VuePress               | Integrated user documentation                    |

### Critical Startup Path

The ecosystem follows a strict initialization order to ensure service discovery:

1. **Infrastructure:** PostgreSQL, MongoDB, Keycloak
2. **Registry:** Config Service → Eureka Service
3. **Core API:** Project Service (Backend)
4. **Interface:** Frontend Service & Support Microservices

## Installation Guides

Choose the setup that matches your environment:

### [Local Setup Guide](../local-setup/README.md)

For developers and testing. Uses Docker Desktop and local `hosts` file entries to simulate the domain environment.

### [Server Setup Guide](../server-setup/README.md)

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
  at [Manual-Develop](https://backend.approved.ibdf-frankfurt.de/manual/updates/).
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

Starting with v1.4.0, the email service requires a 32-bit hex `ENCRYPTION_KEY` in the `.env` file to protect mail-server
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
