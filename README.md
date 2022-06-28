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
    image: kasmweb/kasm:latest
    privileged: true
    container_name: kasm
    environment:
      - KASM_PORT=443 #optional
      - DOCKER_HUB_USERNAME=USER #optional
      - DOCKER_HUB_PASSWORD=PASS #optional
    volumes:
      - /kasm/local/storage:/opt
    ports:
      - 443:443
      - 3000:3000
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
  -p 3000:3000 \
  -v /kasm/local/storage:/opt \
  kasmweb/kasm:latest
```

| Parameter | Function |
| :----: | --- |
| `-p 443` | Kasm Workspaces web UI |
| `-p 3000` | Kasm Installation and upgrade wizard |
| `-v /kasm/local/storage:/opt` | Docker and Kasm Storage |
| `-e KASM_PORT=443` | If not using port 443 this needs to be set to the port you are binding to (optional) |
| `-e DOCKER_HUB_USERNAME=USER` | Dockerhub username for logging in on init (optional) |
| `-e DOCKER_HUB_PASSWORD=PASS` | Dockerhub password for logging in on init (optional) |


# Versions

| Tag | Description |
| :----: | --- |
| latest | Latest stable release |
| develop | Development head |

| Architecture | Tag |
| :----: | ---- |
| x86-64 | x86_64-\<version tag\> |
| arm64 | aarch64-\<version tag\> |
