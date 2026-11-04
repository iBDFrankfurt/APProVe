# APProVe Quick Start

For people who have done this before. First installation? Read the [README](README.md) – it explains every step.

**Windows:** use **Git Bash** for all commands (not PowerShell/CMD).

---

## Checklist

- [ ] Docker Desktop is running (8 GB RAM for Docker)
- [ ] Git + Bash (Git Bash on Windows)
- [ ] GitLab account with access to `uct/open-approve`, VPN connected if outside the institute
- [ ] 5 GB free disk space
- [ ] Port 8080 free (often taken by other dev servers)

No hosts file entries needed: all services use `*.approve.localhost`, which browsers and curl resolve by themselves.

---

## 1. Registry login

Personal Access Token with scope `read_registry`:

```bash
docker login registry.gitlab.ibdf-frankfurt.de
```

## 2. Install

```bash
git clone https://gitlab.ibdf-frankfurt.de/uct/open-approve.git
cd open-approve/local-setup
./install.sh
```

Local PostgreSQL/MongoDB already running? Change `POSTGRES_HOST_PORT` / `MONGO_HOST_PORT` in `.env` first
(e.g. `15432` / `27018`). The installer checks ports, host names and registry login and tells you what to fix.
It is safe to run it again after an error.

## 3. Open APProVe

**http://frontend.approve.localhost:8001** → *Anmelden* → `approve-admin` / `approve-password`

| | |
|---|---|
| Manual | http://localhost:8090/manual/ |
| Keycloak admin | http://auth.approve.localhost:8080/admin (`adminuser` / `adminpass`) |
| Eureka | http://localhost:8761 |

---

## Commands (in `local-setup`)

```bash
docker compose ps                   # status
docker compose logs -f <service>    # logs, e.g. backend-service
docker compose stop                 # stop, data is kept
docker compose up -d                # start again
docker compose down -v && ./install.sh   # start from scratch (deletes all data)
```

## Common problems

| Message | Fix |
|---|---|
| `These host names do not resolve` | curl older than 7.78 – update it (or Git for Windows) |
| `Port … is already in use` | Stop the other program; only the database ports can be changed in `.env` |
| `Pulling the images failed` | `docker login …` again, token needs `read_registry`, VPN |
| `Timeout waiting for …` | `docker compose logs <service>`, give Docker more memory, re-run `./install.sh` |

More in the [README](README.md#troubleshooting).
