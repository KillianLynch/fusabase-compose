# fusabase-compose

Starter Oracle Database + ORDS + Oracle Backend with Firebase APIs (Fusabase) stack using Compose.

## What This Starts

This project starts:

- Oracle AI Database Free 26ai (23.26.3.0)
- Oracle REST Data Services (ORDS) 26.3.0
- Oracle Backend with Firebase APIs (Fusabase)

The first startup configures the database, installs ORDS, enables Fusabase, and prepares a `testuser` sign-in for the Fusabase console.

## Prerequisites

- Podman with Compose support
- Access to pull Oracle container images

## Start The Stack

```bash
podman compose up -d
```

> Docker users: replace `podman` with `docker` in every command in this README — the stack works with either runtime.

The first startup takes longer because the database and ORDS need to initialize.

## Ports

- `1521` Oracle Database listener
- `8080` ORDS HTTP
- `27017` Oracle Database API for MongoDB

## Demo Credentials

### Database / ORDS admin setup

- SYS password: `Welcome12345`

### Fusabase demo user

- username: `testuser`
- password: `testpwd`

## Open ORDS

Open:

```text
http://127.0.0.1:8080/ords/
```

From the landing page, open **Oracle Backend with Firebase APIs**.

## Sign In To Fusabase

On the sign-in page, use:

- Path: `testuser`
- Username: `testuser`
- Password: `testpwd`

The resulting Fusabase URL is:

```text
http://127.0.0.1:8080/ords/testuser/_/baas-console/
```

## What Happens Automatically

On first startup, this stack automatically:

- sets up the Oracle database users needed by the stack
- configures TDE
- installs ORDS 26.2.3 in the database
- installs Oracle Backend with Firebase APIs (Fusabase)
- grants the required Fusabase role to `fusabase_dba`
- enables `TESTUSER` for Fusabase

## Stop The Stack

```bash
podman compose down
```

## Reset The Stack

```bash
podman compose down -v
```

Use this only when you want to remove the containers and associated volumes and start over from a clean state.

## Production Note

This repository uses demo credentials for local setup convenience. Do not use these credentials or this configuration as-is in production.
