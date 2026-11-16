# Docker Kasm

The purpose of this container is to allow a docker enabled system to easily deploy a fully functional Kasm Workspaces application stack isolated in a single container. It's main focus is on the consumer and hobbyist user acting as a stepping stone to a dedicated VM or full multi server deployment. The idea being we make spinning up the stack as simple as possible obfuscating as much as possible away from the user when it comes to installation and management. 

It has a few core principles:
* Have no external dependencies outside of Docker
* All user facing processes must be presented in a web interface
* The installation must be upgraded using Docker
* The container must function in an ephemeral mode along with using a bind mount for a persistent install
* The user should have the option to run development or stable builds

# Usage

### docker-compose

```yaml
---
version: "2.1"
services:
  kasm:
    image: kasmweb/workspaces:1.19.0
    privileged: true
    container_name: kasm
    environment:
      - KASM_PORT=443 #optional
      - KASM_SETUP=false #optional
      - DOCKER_HUB_USERNAME=USER #optional
      - DOCKER_HUB_PASSWORD=PASS #optional
    volumes:
      - /kasm/local/storage:/opt
      - /path/to/profiles:/profiles #optional
      - /dev/input:/dev/input #optional
      - /run/udev/data:/run/udev/data #optional
    ports:
      - 443:443
      - 127.0.0.1:3000:3000
    restart: unless-stopped
```

### docker cli

```
docker run -d \
  --privileged \
  --name=kasm \
  -e KASM_PORT=443 `#optional` \
  -e KASM_SETUP=false `#optional` \
  -e DOCKER_HUB_USERNAME=USER `#optional` \
  -e DOCKER_HUB_PASSWORD=PASS `#optional` \
  -p 443:443 \
  -p 127.0.0.1:3000:3000 \
  -v /kasm/local/storage:/opt \
  -v /path/to/profiles:/profiles `#optional` \
  -v /dev/input:/dev/input `#optional` \
  -v /run/udev/data:/run/udev/data `#optional` \
  kasmweb/workspaces:1.19.0
```

| Parameter | Function |
| :----: | --- |
| `-p 443` | Kasm Workspaces web UI (HTTPS) |
| `-p 127.0.0.1:3000:3000` | Kasm Installation and upgrade wizard (HTTPS), bound to localhost only |
| `-v /kasm/local/storage:/opt` | Docker and Kasm Storage |
| `-v /profiles` | Optionally specify a path for persistent profile storage. |
| `-v /dev/input` | Optional for gamepad support. |
| `-v /run/udev/data` | Optional for gamepad support. |
| `-e KASM_PORT=443` | If not using port 443 this needs to be set to the port you are binding to (optional) |
| `-e KASM_SETUP=false` | Set to `true` to enable the install wizard after Kasm is installed, e.g. to upgrade. First-run setup is always enabled (optional) |
| `-e DOCKER_HUB_USERNAME=USER` | Dockerhub username for logging in on init (optional) |
| `-e DOCKER_HUB_PASSWORD=PASS` | Dockerhub password for logging in on init (optional) |


## First-run setup

1. Start the container and read the wizard's setup token from the logs (a new one is printed each time the wizard starts):
   ```
   docker logs kasm 2>&1 | grep -A1 'setup token (required' | tail -1
   ```
2. Open `https://127.0.0.1:3000/#token=<token>` (or enter the token when prompted) and complete the install.
3. Log in at `https://<host>:443`. Once the install finishes the wizard stops automatically (unless `KASM_SETUP=true`).

If `/opt/NO_WIZARD` exists (created by "Stop Install Wizard"), the wizard does not start; delete it and restart the container.

If the install fails before Kasm's services are started (no `/opt/kasm/current` yet), fix the cause and retry from the wizard; the retry starts over, including the database that attempt seeded (after a container restart, the wizard comes back for the retry). If it fails or is interrupted later, the wizard will not run the installer again, because that would reset the database. To start over, remove the container and empty the `/opt` storage directory (`/kasm/local/storage` above). This deletes all Kasm data.

The wizard is bound to `127.0.0.1` in the examples above. On a headless host, reach it through an SSH tunnel (`ssh -L 3000:127.0.0.1:3000 <host>`) rather than publishing it on the network. **Never expose port 3000 to the internet.**

## Upgrading

Pull the new image, recreate the container with `KASM_SETUP=true`, open the wizard with the new token from the logs and run the upgrade. Then set `KASM_SETUP=false` and recreate the container again. If `/opt/NO_WIZARD` exists (created by "Stop Install Wizard"), delete it first.

# Versions

| Tag | Description |
| :----: | --- |
| 1.15.0 | Latest stable release |
| develop | Development head |

| Architecture | Tag |
| :----: | ---- |
| x86-64 | x86_64-\<version tag\> |
| arm64 | aarch64-\<version tag\> |
