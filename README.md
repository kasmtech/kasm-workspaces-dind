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
    image: kasmweb/workspaces:1.18.1
    privileged: true
    container_name: kasm
    environment:
      - KASM_PORT=443 #optional
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
  -e DOCKER_HUB_USERNAME=USER `#optional` \
  -e DOCKER_HUB_PASSWORD=PASS `#optional` \
  -p 443:443 \
  -p 127.0.0.1:3000:3000 \
  -v /kasm/local/storage:/opt \
  -v /path/to/profiles:/profiles `#optional` \
  -v /dev/input:/dev/input `#optional` \
  -v /run/udev/data:/run/udev/data `#optional` \
  kasmweb/workspaces:1.18.1
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
| `-e DOCKER_HUB_USERNAME=USER` | Dockerhub username for logging in on init (optional) |
| `-e DOCKER_HUB_PASSWORD=PASS` | Dockerhub password for logging in on init (optional) |


## First-run setup

1. Start the container and read the wizard's setup token from the logs (a new one is printed each time the wizard starts):
   ```
   docker logs kasm 2>&1 | grep -A1 'setup token (required' | tail -1
   ```
2. Open `https://127.0.0.1:3000/#token=<token>` (or enter the token when prompted) and complete the install.
3. Log in at `https://<host>:443`.

The wizard keeps running after the install so it can be used for upgrades. To turn it off, click "Stop Install Wizard". This creates `/opt/NO_WIZARD`, and the wizard stays off until you delete that file and restart the container.

If the install fails before Kasm's services are started (no `/opt/kasm/current` yet), fix the cause and retry from the wizard; the retry starts over, including the database that attempt seeded. If it fails or is interrupted later, the wizard will not run the installer again, because that would reset the database. To start over, remove the container and empty the `/opt` storage directory (`/kasm/local/storage` above). This deletes all Kasm data.

Port 3000 is published as `127.0.0.1:3000` in the examples above, so the wizard can only be opened from the host itself. Other machines on your network, and the internet, cannot reach it. Keep it that way: the wizard can install and upgrade Kasm. On a headless host, use an SSH tunnel (`ssh -L 3000:127.0.0.1:3000 <host>`) and open `https://127.0.0.1:3000` on your own machine. **Never expose port 3000 to the internet.**

## Upgrading

Pull the new image and recreate the container (if `/opt/NO_WIZARD` exists, delete it first). Then open the wizard with the new token from the logs and run the upgrade.

# Versions

| Tag | Description |
| :----: | --- |
| 1.15.0 | Latest stable release |
| develop | Development head |

| Architecture | Tag |
| :----: | ---- |
| x86-64 | x86_64-\<version tag\> |
| arm64 | aarch64-\<version tag\> |


# Reporting Issues

To report any issues for this repository, please use our central issue tracker: **[Kasm Workspaces Issue Tracker](https://github.com/kasmtech/workspaces-issues/issues)**
