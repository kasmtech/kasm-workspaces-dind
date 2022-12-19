FROM ubuntu:jammy

# Settings
ARG OVERLAY_VERSION="v2.2.0.3"
ARG RELEASE_TYPE="stable"
ENV DOCKER_TLS_CERTDIR=""

# Container setup
RUN \
  echo "**** install packages ****" && \
  apt-get update && \
  apt-get install -y \
    curl \
    gnupg && \
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
  ARCH=$(uname -m | sed 's/x86_64/amd64/g' |sed 's/aarch64/arm64/g') && \
  echo "deb [arch=${ARCH}] https://download.docker.com/linux/ubuntu jammy stable" > \
    /etc/apt/sources.list.d/docker.list && \
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
    gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && \
  curl -s -L https://nvidia.github.io/libnvidia-container/ubuntu22.04/libnvidia-container.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list && \
  curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
  apt-get install -y --no-install-recommends \
    bash \
    btrfs-progs \
    containerd.io \
    docker-ce \
    docker-ce-cli \
    docker-compose-plugin \
    drm-info \
    e2fsprogs \
    fuse-overlayfs \
    g++ \
    gcc \
    iptables \
    jq \
    make \
    nodejs \
    nvidia-docker2 \
    openssl \
    pigz \
    python3 \
    sudo \
    uidmap \
    xfsprogs && \
  echo "**** dind setup ****" && \
  useradd -U dockremap && \
  usermod -G dockremap dockremap && \
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
  if [ "${RELEASE_TYPE}" = "develop" ]; then \
    KASM_VERSION=$(curl -sX GET https://kasm-ci.s3.amazonaws.com/dev-version.txt); \
  fi; \
  if [ "${RELEASE_TYPE}" = "stable" ]; then \
    KASM_VERSION=$(curl -sX GET 'https://api.github.com/repos/kasmtech/kasm-install-wizard/releases/latest' \
    | jq -r '.name'); \
  fi; \
  echo "${KASM_VERSION}" > /version.txt && \
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
    /kasm_release/www/img/thumbnails/*.png /kasm_release/www/img/thumbnails/*.svg \
    /wizard/public/img/thumbnails/ && \
  cp \
    /kasm_release/conf/database/seed_data/default_images_a* \
    /wizard/ && \
  echo "**** cleanup ****" && \
  apt-get remove -y g++ gcc make && \
  apt-get -y autoremove && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# add init files
COPY root/ /

# Ports volumes and init
EXPOSE 3000 443
VOLUME /opt/
ENTRYPOINT ["/init"]
