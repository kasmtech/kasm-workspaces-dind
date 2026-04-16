FROM ubuntu:noble

# Settings
ARG OVERLAY_VERSION="v2.2.0.3"
ARG RELEASE_TYPE="stable"
ENV DOCKER_TLS_CERTDIR="" \
    NVIDIA_DRIVER_CAPABILITIES="compute,graphics,video,utility"

# Container setup
RUN \
  echo "**** install packages ****" && \
  apt-get update && \
  apt-get install -y \
    curl \
    gnupg && \
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
  ARCH=$(uname -m | sed 's/x86_64/amd64/g' |sed 's/aarch64/arm64/g') && \
  echo "deb [arch=${ARCH}] https://download.docker.com/linux/ubuntu noble stable" > \
    /etc/apt/sources.list.d/docker.list && \
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
    gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && \
  curl -s -L https://nvidia.github.io/libnvidia-container/ubuntu24.04/libnvidia-container.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list && \
  curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
  apt-get install -y --no-install-recommends \
    bash \
    btrfs-progs \
    containerd.io \
    docker-ce \
    docker-ce-cli \
    e2fsprogs \
    fuse-overlayfs \
    g++ \
    gcc \
    iproute2 \
    iptables \
    jq \
    lsof \
    make \
    nodejs \
    nvidia-container-toolkit \
    nvidia-docker2 \
    openssl \
    pigz \
    python3 \
    sudo \
    uidmap \
    xfsprogs && \
  echo "**** compose install ****" && \
  mkdir -p /usr/local/lib/docker/cli-plugins && \
  curl -L \
    https://github.com/docker/compose/releases/download/v2.29.6/docker-compose-$(uname -s)-$(uname -m) -o \
    /usr/local/lib/docker/cli-plugins/docker-compose && \ 
  chmod +x /usr/local/lib/docker/cli-plugins/docker-compose && \
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
    "https://kasm-static-content.s3.amazonaws.com/kasm_release_${KASM_VERSION}.tar.gz" && \
  tar xf \
    /tmp/kasm.tar.gz -C \
    / && \
  sed -i 's/-N -e -H/-N -B -e -H/g' /kasm_release/upgrade.sh && \
  echo "exit 0" > /kasm_release/install_dependencies.sh && \
  # Set dependencies
  /kasm_release/bin/utils/yq_$(uname -m) -i \
    '.services.proxy.depends_on = {"kasm_manager":{"condition": "service_healthy"},"kasm_api":{"condition": "service_healthy"},"kasm_agent":{"condition": "service_started"},"kasm_guac":{"condition": "service_started"}}' \
    /kasm_release/docker/docker-compose-all.yaml && \
  /kasm_release/bin/utils/yq_$(uname -m) -i \
    '.services.kasm_manager.depends_on = {"db":{"condition": "service_healthy"}}' \
    /kasm_release/docker/docker-compose-all.yaml && \
  /kasm_release/bin/utils/yq_$(uname -m) -i \
    '.services.kasm_api.depends_on = {"db":{"condition": "service_healthy"}}' \
    /kasm_release/docker/docker-compose-all.yaml && \
  /kasm_release/bin/utils/yq_$(uname -m) -i \
    '.services.kasm_api.healthcheck += {"start_period": "60s","start_interval": "30s"}' \
    /kasm_release/docker/docker-compose-all.yaml && \
  /kasm_release/bin/utils/yq_$(uname -m) -i \
    '.services.kasm_rdp_https_gateway.depends_on = {"proxy":{"condition": "service_started"}}' \
    /kasm_release/docker/docker-compose-all.yaml && \
  useradd -u 70 kasm_db && \
  useradd kasm && \
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
