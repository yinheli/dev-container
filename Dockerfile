FROM docker.io/library/debian:stable

# Copy uv from official image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Copy Deno from official image
COPY --from=docker.io/denoland/deno:bin-2.4.3 /deno /usr/local/bin/deno

# Copy Bun from official image
COPY --from=docker.io/oven/bun:latest /usr/local/bin/bun /usr/local/bin/bunx /usr/local/bin/

# Update system and install base dependencies
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    build-essential \
    git \
    git-extras \
    curl \
    wget \
    vim \
    sudo \
    openssh-client \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    gnupg \
    lsb-release \
    locales \
    locales-all

# Configure locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    sed -i '/zh_CN.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Install development tools
RUN apt-get install -y \
    jq \
    tmux \
    htop \
    tree \
    unzip \
    zip \
    protobuf-compiler \
    pkg-config \
    libssl-dev

# Install Node.js LTS via NodeSource repository
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs

# Install pnpm and yarn
RUN npm install -g pnpm yarn

# Install Go from official repository
RUN ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
        amd64) GOARCH='amd64' ;; \
        arm64) GOARCH='arm64' ;; \
        armhf) GOARCH='armv6l' ;; \
        *) echo "Unsupported architecture: ${ARCH}" && exit 1 ;; \
    esac && \
    wget -O- "https://go.dev/dl/go1.24.5.linux-${GOARCH}.tar.gz" | tar -C /usr/local -xzf -
ENV PATH="/usr/local/go/bin:${PATH}"

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
apt-get update && \
apt-get install -y gh

# Install Rust as root
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install cargo-binstall and cargo tools using pre-compiled binaries
RUN cargo install cargo-binstall && \
    cargo binstall -y \
    ast-grep \
    ripgrep \
    fd-find \
    typos-cli \
    cargo-deny \
    cargo-nextest \
    cargo-generate \
    cargo-udeps \
    cargo-outdated \
    cargo-expand \
    --locked && \
    rm -rf /root/.cargo/registry && \
    rm -rf /root/.cargo/git && \
    rm -rf /tmp/*

# Install Claude Code globally and clean npm cache
RUN npm install -g @anthropic-ai/claude-code && \
    npm cache clean --force

# Clean package cache
RUN apt-get autoremove -y && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/*

# Copy tmux configuration
COPY .tmux.conf /root/.tmux.conf

# Set working directory
WORKDIR /workspace

# Set shell to bash
SHELL ["/bin/bash", "-c"]

ENV IS_SANDBOX=1

CMD tmux new-session -d -s dev -n claude 'claude --dangerously-skip-permissions' \; \
    new-window -n terminal \; \
    select-window -t claude \; \
    attach-session
