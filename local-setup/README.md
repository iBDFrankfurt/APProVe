# APProVe – Local Installation Guide

> **Version:** 4.0.0
> **Last Updated:** October 2026

This guide installs the complete APProVe stack (13 Docker containers) on your own computer, for testing and
development. It is written for people who install APProVe for the first time. If you have done this before, the
[Quickstart](Quickstart.md) is enough.

**Time needed:** about 15 minutes of your time, plus 5–15 minutes of waiting for the first image download.

---

## Table of Contents

- [Before you start](#before-you-start)
- [Installation](#installation)
- [First login](#first-login)
- [Your first project](#your-first-project)
- [Everyday use: stop, start, update, reset](#everyday-use-stop-start-update-reset)
- [What is running](#what-is-running)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)

---

## Before you start

### What you need

| What | Why | Check with |
|---|---|---|
| **Docker Desktop** (Windows/macOS) or Docker Engine + Compose plugin (Linux) | Runs all APProVe services | `docker info` and `docker compose version` |
| **Git** | Downloads this repository and two small dependencies | `git --version` |
| **A Bash shell** – on Windows **Git Bash** (comes with [Git for Windows](https://git-scm.com/downloads)) | The installer is a Bash script. CMD and PowerShell do **not** work. | open "Git Bash" from the start menu |
| **A GitLab account on `gitlab.ibdf-frankfurt.de`** with access to `uct/open-approve` | The APProVe images are in its private registry | log in at https://gitlab.ibdf-frankfurt.de |
| **8 GB RAM for Docker**, 5 GB free disk | 13 containers incl. 6 Java services | Docker Desktop → Settings → Resources |
| Maven + JDK 11+ *(optional)* | Builds the Keycloak event listener. If missing, the installer builds it inside a Docker container instead. | `mvn -v` |

> **Windows:** run every command in this guide in **Git Bash**, not in PowerShell or CMD.
> On Linux, add your user to the `docker` group (`sudo usermod -aG docker $USER`, then log out and in again).

### How APProVe is reached

The services talk to each other – and your browser talks to them – via host names like `approve.frontend` or
`approve.auth`. Your computer only knows these names after you add them to its **hosts file** (step 2). This is
the most common reason for a failed first installation.

---

## Installation

### Step 1: Get the repository

```bash
git clone https://gitlab.ibdf-frankfurt.de/uct/open-approve.git
cd open-approve/local-setup
```

Git asks for your GitLab username and password (or a Personal Access Token, see step 3). All following commands are
run in this `local-setup` folder.

### Step 2: Add the host names to your hosts file

Add this **one line** at the end of your hosts file:

```text
127.0.0.1 approve.frontend approve.auth approve.backend approve.user approve.comment approve.mails approve.automation approve.import
```

- **Windows:** press the Windows key, type `Notepad`, right-click → **Run as administrator**. Then *File → Open*
  `C:\Windows\System32\drivers\etc\hosts` (set the file filter to "All files"), paste the line, save.
- **macOS/Linux:** `sudo nano /etc/hosts`, paste the line, save with `Ctrl+O`, `Enter`, `Ctrl+X`.

Check it (the address must be `127.0.0.1`):

```bash
ping -c 1 approve.frontend    # Windows Git Bash: ping -n 1 approve.frontend
```

### Step 3: Log in to the image registry

The APProVe images are stored in the GitLab registry. Create a **Personal Access Token**:

1. Open https://gitlab.ibdf-frankfurt.de → your avatar → **Edit profile** → **Access tokens** → **Add new token**
2. Select the scope **`read_registry`** (add `read_repository` if you also want to use it for `git clone`)
3. Create it and copy the token – GitLab shows it only once

Then log in (username = your GitLab username, password = the token):

```bash
docker login registry.gitlab.ibdf-frankfurt.de
```

You should see `Login Succeeded`. If you skip this step, the installer asks for it.

### Step 4: Check for port conflicts *(only if you run databases locally)*

APProVe publishes its services on these ports of your computer:
`8000, 8001, 8003, 8080, 8090, 8761, 8888, 9001, 3233, 3234, 4234` and the database ports `5432` (PostgreSQL) and
`27017` (MongoDB).

If you already have **PostgreSQL** or **MongoDB** installed on your computer, their ports are taken. Then open `.env`
and change the defaults of these two lines (only the number after `:-`):

```bash
POSTGRES_HOST_PORT=${POSTGRES_HOST_PORT:-15432}
MONGO_HOST_PORT=${MONGO_HOST_PORT:-27018}
```

The installer checks all ports before starting anything and tells you exactly which one is taken, so you can also
just start with step 5 and come back here if needed.

### Step 5: Run the installer

```bash
./install.sh
```

If you get `Permission denied`, run `chmod +x install.sh` once.

The script reports every step it completes. What it does:

1. Checks Docker, Docker Compose, Git, curl, free disk space, the hosts file and the registry login
2. Checks that all required ports are free
3. Downloads the Keycloak login theme and the Keycloak event listener into this folder and builds the listener
4. Downloads the Docker images (the slow part on the first run)
5. Starts PostgreSQL, MongoDB, the config service, Eureka and Keycloak – each one waits until the previous one is ready
6. Configures Keycloak: realm `local-test` (login valid for 30 minutes), client `APProVe-Web`, service user,
   event listener
7. Starts the backend, creates the APProVe admin and checks that it reached the backend
8. Starts all remaining services and checks that every container is running

At the end you see the URLs and login data. The whole output is also written to `install.log`.

> **Safe to re-run:** if something fails, the script stops with a message that names the problem (and shows the last
> log lines of the affected service). The containers are kept so you can look at them. Fix the cause and simply run
> `./install.sh` again – existing data and configuration are kept.

---

## First login

| | |
|---|---|
| **APProVe** | http://approve.frontend:8001 |
| **User** | `approve-admin` |
| **Password** | `approve-password` |

1. Open http://approve.frontend:8001 – you see the APProVe welcome page.
2. Click **Anmelden** (top right or in the text). You are forwarded to the Keycloak login page (`approve.auth:8080`).
3. Log in with the data above. You are sent back to APProVe and see the dashboard.

The user interface is in German. The `approve-admin` user has the role `APPROVE_ADMIN_ROLE` and can see everything,
including the **Administration** area.

Other logins:

| What | URL | Login |
|---|---|---|
| Keycloak admin console (users, roles) | http://approve.auth:8080/admin | `adminuser` / `adminpass` |
| User manual | http://localhost:8090/manual/ | – |
| Eureka (which services are registered) | http://localhost:8761 | – |
| Service account used by the services | – | `restuser` / `restuser_pass` |

All of these are set in `.env`. They are for local use only – never use them on a server.

---

## Your first project

A short tour to see that everything works. The user manual (http://localhost:8090/manual/) explains every page
in detail.

1. Click **Neues Projekt +** in the top bar and confirm the realm **UCT** with **Auswählen**. The form opens in a
   new browser tab.
2. The form has five steps (left menu). A step turns green when everything required is filled in:
   - **Allgemeines:** project title, runtime in months, a project leader (type at least 3 letters of a last name,
     e.g. `User`, and pick *User, Admin*), a main focus (*Schwerpunkt*, e.g. *UCT*), a cost centre and the
     request type (*Antragsart*, e.g. *Neuantrag*)
   - **Abstract:** background, objective, prior work and methods – enter `-` in a field you want to leave empty
   - **Bioproben & Daten:** samples are optional. Under *Patientendaten* tick at least one option
     (e.g. *Ich nutze bzw. erhebe selbst Daten* → *Eigene Daten*)
   - **Ethik & Finanzierung:** choose one financing option (e.g. *Projektfinanzierung ist nicht vorhanden*)
   - **Nutzungsbedingungen:** accept the terms of use
3. Click **Weiter** to open the summary (*Zusammenfassung und Projekteinreichung*), check it and click
   **Projekt einreichen**. You are taken to the project page: it has the number `UCT-1-<year>` and the status
   *eingereicht*.
4. To edit, click **Bearbeiten** next to a section on the project page (e.g. *Allgemeine Daten*), change a value
   (e.g. the runtime) and click **Speichern**. You see *Projekt erfolgreich bearbeitet*.

> **Fill in the form in one go.** Entries are lost when you reload the page. A login is valid for 30 minutes
> (`KEYCLOAK_ACCESS_TOKEN_LIFESPAN` in `.env`); after that, submitting fails with "Request failed with status
> code 401" – reload the page to log in again.

> **New users:** create them in the Keycloak admin console (realm `local-test` → *Users* → *Add user*, then set a
> password under *Credentials* and assign roles under *Role mapping*). The event listener copies every user and role
> change from Keycloak to APProVe automatically.

---

## Everyday use: stop, start, update, reset

Run these commands in the `local-setup` folder.

| I want to … | Command | Data |
|---|---|---|
| see what is running | `docker compose ps` | – |
| stop APProVe (e.g. at the end of the day) | `docker compose stop` | kept |
| start it again | `docker compose up -d` | kept |
| restart one service | `docker compose restart backend-service` | kept |
| follow the logs | `docker compose logs -f backend-service` | – |
| get newer images | `docker compose pull && docker compose up -d` | kept |
| remove the containers | `docker compose down` | kept (volumes stay) |
| **start from scratch** | `docker compose down -v` and then `./install.sh` | **deleted** |

Docker Desktop starts the containers again automatically after a reboot. The services need 1–2 minutes until
everything is ready; Go services may log connection errors during that time and then recover by themselves.

The service names for these commands are: `auth`, `postgres`, `mongo`, `config-service`, `eureka-service`,
`backend-service`, `frontend-service`, `user-service`, `comments-service`, `mail-service`, `automation-service`,
`import-service`, `manual-service`.

If you have `make` installed, `make help` lists shortcuts for the same commands.

---

## What is running

| Service | Container | Port on your computer | Purpose |
|---|---|---|---|
| Frontend | `approve.frontend` | 8001 | Web interface (what you open in the browser) |
| Backend (project service) | `approve.backend` | 8000 | Core logic: projects, users, roles (`/api`) |
| Keycloak | `approve.auth` | 8080 | Login and user management |
| User service | `approve.user` | 9001 | User administration via Keycloak |
| Import service | `approve.import` | 8003 | Import/export of projects, API keys |
| Comment service | `approve.comment` | 3234 | Project comments (Go) |
| Mail service | `approve.mails` | 4234 | E-mail templates and sending (Go) |
| Automation service | `approve.automation` | 3233 | Automation rules (Go) |
| Manual | `approve.manual` | 8090 | User manual (`/manual/`) |
| Config service | `approve.config` | 8888 | Central configuration for the Java services |
| Eureka | `approve.eureka` | 8761 | Service registry |
| PostgreSQL | `approve.postgres` | `POSTGRES_HOST_PORT` (5432) | Projects, users, Keycloak |
| MongoDB | `approve.mongo` | `MONGO_HOST_PORT` (27017) | Comments, mails, automation rules |

Start order (the installer takes care of it): PostgreSQL + MongoDB → config service → Eureka → Keycloak → backend →
all others.

---

## Troubleshooting

First look at what the installer printed – it names the failed step and shows the last log lines of the affected
service. For a full report run `./diagnose.sh`.

### "These host names do not resolve: …"

The hosts file entry from step 2 is missing or was not saved (on Windows, Notepad must run as administrator).
Add the line the script prints and run `./install.sh` again.

### "Port 5432 (POSTGRES_HOST_PORT) is already in use"

Another program uses the port – usually a locally installed database or another Docker project. Either stop it, or
change the port in `.env` (see step 4). For the service ports (8000, 8001, 8080, …) stop the other program; changing
them also requires changing the matching URLs in `.env`.

### "Pulling the images failed" / "pull access denied" / "unauthorized"

- Log in again: `docker login registry.gitlab.ibdf-frankfurt.de`
- Your token needs the scope `read_registry`, and your GitLab account needs access to `uct/open-approve`
- Outside the institute network: connect the VPN

### "The Keycloak event listener could not be built"

Neither a local Maven build nor the Docker build worked. Details are in `install.log`. Usually Docker cannot download
the `maven` image (network/proxy) – try `docker pull maven:3.9-eclipse-temurin-17`.

### "The admin user was not found in the backend database"

Keycloak did not hand the admin over to the backend. Check that the listener was loaded:
`docker compose logs auth | grep -i "event listener"` should show `Initializing Event Listener Factory`. If not,
check that `keycloak-event-listener/target/keycloak-event-listener.jar` exists and run `./install.sh` again.

### "Timeout waiting for …" / a service does not start

```bash
docker compose ps                      # which container is not running / unhealthy?
docker compose logs --tail=100 <service>
```

Common causes: Docker has too little memory (Docker Desktop → Settings → Resources → at least 8 GB) or the computer
was busy. Run `./install.sh` again – it continues where it stopped.

### The browser shows "This site can't be reached"

1. `ping approve.frontend` must answer from `127.0.0.1` (hosts file, step 2)
2. `docker compose ps` must show `approve.frontend` as running
3. The frontend needs about a minute after start; reload the page

### After login the page stays empty or shows errors

Open the browser console (F12). If requests to `approve.backend`, `approve.user` etc. fail, those host names are
missing in the hosts file – the browser calls these services directly.

### `/bin/bash^M: bad interpreter`

The files were checked out with Windows line endings. Run `sed -i 's/\r$//' install.sh` or configure Git with
`git config --global core.autocrlf input` and clone again.

---

## FAQ

### Can I use this setup in production?

No. It uses fixed passwords, plain HTTP and no backups. For a server use the [server setup](../server-setup).

### How do I connect a database tool?

PostgreSQL: host `localhost`, port `POSTGRES_HOST_PORT` (default 5432), user `postgres_admin`, password
`postgres_admin_pass`, databases `approve_db` (APProVe) and `auth_db` (Keycloak).
MongoDB: `mongodb://mongo_admin:mongopass@localhost:27017` (port = `MONGO_HOST_PORT`).

Or directly in the container:

```bash
docker exec -it approve.postgres psql -U postgres_admin -d approve_db
docker exec -it approve.mongo mongosh -u mongo_admin -p mongopass
```

### How do I back up and restore the data?

```bash
# Backup
docker exec approve.postgres pg_dump -U postgres_admin approve_db > backup_postgres.sql
docker exec approve.mongo mongodump -u mongo_admin -p mongopass --out=/tmp/backup
docker cp approve.mongo:/tmp/backup ./backup_mongo

# Restore
docker exec -i approve.postgres psql -U postgres_admin approve_db < backup_postgres.sql
docker cp ./backup_mongo approve.mongo:/tmp/backup
docker exec approve.mongo mongorestore -u mongo_admin -p mongopass /tmp/backup
```

### Can I change the ports or passwords?

Yes, everything is in `.env`. Port changes need the matching URL in `.env` changed as well. Changes to the
Keycloak or admin settings only take effect on a fresh installation (`docker compose down -v`, then `./install.sh`).

---

## More

- User manual: http://localhost:8090/manual/ (after the installation)
- Keycloak documentation: https://www.keycloak.org/documentation
- Docker documentation: https://docs.docker.com
