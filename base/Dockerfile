FROM debian:bookworm-slim

ARG HOST_UID=1000
ARG HOST_GID=1000
ARG NODE_VERSION=23.11.1
ARG GO_VERSION=1.24.2
ARG LOCAL_TOOLS="git curl jq ripgrep vim nano make zip unzip openssh-client wget tree imagemagick build-essential python3 python3-pip pipx ca-certificates gnupg less groff-base xz-utils procps"

# 1. Install base system dependencies
RUN apt-get update && \
  apt-get install -y --no-install-recommends ${LOCAL_TOOLS} && \
  rm -rf /var/lib/apt/lists/*

# 2. Install Node.js from the official binary tarball
RUN ARCH="$(dpkg --print-architecture)" && \
  case "${ARCH}" in \
    amd64) NODE_ARCH="x64" ;; \
    arm64) NODE_ARCH="arm64" ;; \
    *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;; \
  esac && \
  curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" -o /tmp/node.tar.xz && \
  tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 && \
  rm -f /tmp/node.tar.xz && \
  node --version && \
  npm --version

# 3. Install Go from the official binary tarball
RUN ARCH="$(dpkg --print-architecture)" && \
  case "${ARCH}" in \
    amd64) GO_ARCH="amd64" ;; \
    arm64) GO_ARCH="arm64" ;; \
    *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;; \
  esac && \
  curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" -o /tmp/go.tar.gz && \
  rm -rf /usr/local/go && \
  tar -C /usr/local -xzf /tmp/go.tar.gz && \
  rm -f /tmp/go.tar.gz && \
  /usr/local/go/bin/go version

# 4. Install AWS CLI v2 using the official bundled installer
RUN ARCH="$(dpkg --print-architecture)" && \
  case "${ARCH}" in \
    amd64) AWS_ARCH="x86_64" ;; \
    arm64) AWS_ARCH="aarch64" ;; \
    *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;; \
  esac && \
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" -o /tmp/awscliv2.zip && \
  unzip -q /tmp/awscliv2.zip -d /tmp && \
  /tmp/aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli && \
  rm -rf /tmp/aws /tmp/awscliv2.zip && \
  aws --version

# 5. Install kubectl from the official Kubernetes apt repository
RUN install -m 0755 -d /etc/apt/keyrings && \
  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
  chmod 0644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /" > /etc/apt/sources.list.d/kubernetes.list && \
  chmod 0644 /etc/apt/sources.list.d/kubernetes.list && \
  apt-get update && \
  apt-get install -y --no-install-recommends kubectl && \
  kubectl version --client && \
  rm -rf /var/lib/apt/lists/*

# 6. Install Terraform from the official HashiCorp apt repository
RUN install -m 0755 -d /etc/apt/keyrings && \
  curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
  chmod 0644 /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo \"${VERSION_CODENAME}\") main" > /etc/apt/sources.list.d/hashicorp.list && \
  apt-get update && \
  apt-get install -y --no-install-recommends terraform && \
  terraform version && \
  rm -rf /var/lib/apt/lists/*

# 7. Install OpenTofu from the official apt repository
RUN install -m 0755 -d /etc/apt/keyrings && \
  curl -fsSL https://get.opentofu.org/opentofu.gpg > /etc/apt/keyrings/opentofu.gpg && \
  curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey | gpg --no-tty --batch --dearmor -o /etc/apt/keyrings/opentofu-repo.gpg && \
  chmod 0644 /etc/apt/keyrings/opentofu.gpg /etc/apt/keyrings/opentofu-repo.gpg && \
  echo "deb [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main" > /etc/apt/sources.list.d/opentofu.list && \
  chmod 0644 /etc/apt/sources.list.d/opentofu.list && \
  apt-get update && \
  apt-get install -y --no-install-recommends tofu && \
  tofu version && \
  rm -rf /var/lib/apt/lists/*

# 8. Install Bun by copying from the official image
COPY --from=oven/bun:1 /usr/local/bin/bun /usr/local/bin/bun
RUN ln -s /usr/local/bin/bun /usr/local/bin/bunx

# 9. Install Playwright system dependencies for Chromium
RUN npx playwright install-deps chromium

# 10. Enable Corepack
RUN corepack enable

# 11. Create the runtime user and workspace
RUN groupadd --gid "${HOST_GID}" agent && \
  useradd --uid "${HOST_UID}" --gid "${HOST_GID}" --create-home --shell /bin/bash agent && \
  install -d -o agent -g agent /app

WORKDIR /app

# 12. Switch to the non-root runtime user
USER agent

ENV NPM_CONFIG_PREFIX=/home/agent/.npm-global
ENV BUN_INSTALL=/home/agent/.bun
ENV GOROOT=/usr/local/go
ENV GOPATH=/home/agent/go
ENV PATH=/home/agent/.local/bin:/home/agent/.npm-global/bin:/home/agent/.bun/bin:/home/agent/go/bin:/usr/local/go/bin:${PATH}

RUN mkdir -p /home/agent/.npm-global && \
  mkdir -p /home/agent/.config && \
  mkdir -p /home/agent/.local/bin && \
  mkdir -p /home/agent/.bun/bin && \
  mkdir -p /home/agent/go/bin

# 13. Install Ansible with pipx for the runtime user
RUN pipx --version && \
  pipx install ansible-core && \
  ansible --version

# 14. Install agent-browser for the runtime user
RUN npm install -g agent-browser && \
  agent-browser install

# 15. Configure the interactive shell
RUN echo "export PATH=/home/agent/.local/bin:/home/agent/.npm-global/bin:/home/agent/.bun/bin:/home/agent/go/bin:/usr/local/go/bin:\$PATH" >> /home/agent/.bashrc

# 16. Copy aliases
COPY --chown=agent:agent ./.bash_aliases /home/agent/.bash_aliases
RUN echo "if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi" >> /home/agent/.bashrc

CMD ["/bin/bash"]
