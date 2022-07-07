FROM alpine:3.16

# Settings
ARG OVERLAY_VERSION="v2.2.0.3"
ARG RELEASE_TYPE="develop"
ENV DOCKER_TLS_CERTDIR=""

# Container setup
RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --virtual=build-dependencies \
    alpine-sdk \
    npm && \
  echo "**** install packages ****" && \
  apk add --no-cache \
    bash \
    btrfs-progs \
    ca-certificates \
    coreutils \
    curl \
    docker \
    docker-cli-compose \
    e2fsprogs \
    e2fsprogs-extra \
    findutils \
    fuse-overlayfs \
    ip6tables \
    iptables \
    jq \
    nodejs \
    openssl \
    pigz \
    procps \
    python3 \
    shadow \
    shadow-uidmap \
    sudo \
    tzdata \
    xfsprogs \
    xz \
    zfs && \
  echo "**** dind setup ****" && \
  addgroup -S dockremap && \
  adduser -S -G dockremap dockremap && \
  echo 'dockremap:165536:65536' >> /etc/subuid && \
  echo 'dockremap:165536:65536' >> /etc/subgid && \
  curl -o \
  /usr/local/bin/dind -L \
    https://raw.githubusercontent.com/moby/moby/master/hack/dind && \
  chmod +x /usr/local/bin/dind && \
  echo 'hosts: files dns' > /etc/nsswitch.conf && \
  echo "**** setup init ****" && \
  curl -o \
    /tmp/s6-overlay-installer -L \
    https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-$(uname -m | sed 's/x86_64/amd64/g')-installer && \
  chmod +x /tmp/s6-overlay-installer && \
  /tmp/s6-overlay-installer / && \
  echo "**** setup wizard ****" && \
  mkdir -p /wizard && \
  if [ "${RELEASE_TYPE}" == "develop" ]; then \
    KASM_VERSION=$(curl -sX GET 'https://api.github.com/repos/kasmtech/kasm-install-wizard/releases' \
    | jq -r '[.[] | select (.prerelease==true)][0].name'); \
  fi; \
  if [ "${RELEASE_TYPE}" == "stable" ]; then \
    KASM_VERSION=$(curl -sX GET 'https://api.github.com/repos/kasmtech/kasm-install-wizard/releases/latest' \
    | jq -r '.name'); \
  fi; \
  echo $KASM_VERSION && \
  curl -o \
    /tmp/wizard.tar.gz -L \
    "https://github.com/kasmtech/kasm-install-wizard/archive/refs/tags/${KASM_VERSION}.tar.gz" && \
  tar xf \
    /tmp/wizard.tar.gz -C \
    /wizard --strip-components=1 && \
  cd /wizard && \
  npm install && \
  echo "**** add installer ****" && \
  curl -o \
    /tmp/kasm.tar.gz -L \
    "https://github.com/kasmtech/kasm-install-wizard/releases/download/${KASM_VERSION}/kasm_release.tar.gz" && \
  tar xf \
    /tmp/kasm.tar.gz -C \
    / && \
  echo "**** copy assets ****" && \
  cp \
    /kasm_release/www/img/thumbnails/*.png \
    /wizard/public/img/thumbnails/ && \
  cp \
    /kasm_release/conf/database/seed_data/default_images_a* \
    /wizard/ && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /root/.npm \
    /root/.cache \
    /tmp/*

# add init files
COPY root/ /

# Ports volumes and init
EXPOSE 3000 443
VOLUME /opt/
ENTRYPOINT ["/init"]
