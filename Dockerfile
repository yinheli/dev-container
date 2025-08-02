FROM docker.io/library/debian:stable

# Copy uv from official image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Copy Deno from official image
COPY --from=docker.io/denoland/deno:bin-2.4.3 /deno /usr/local/bin/deno

# Copy Bun from official image
COPY --from=docker.io/oven/bun:latest /usr/local/bin/bun /usr/local/bin/bun

# Update system and install base dependencies
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    vim \
    sudo \
    openssh-client \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    gnupg \
    lsb-release

# Install development tools
RUN apt-get install -y \
    jq \
    tmux \
    htop \
    tree \
    unzip \
    zip \
    protobuf-compiler

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

# Install useful tools
# Install ripgrep
RUN ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
        amd64) RIPGREP_ARCH='x86_64-unknown-linux-musl' ;; \
        arm64) RIPGREP_ARCH='aarch64-unknown-linux-musl' ;; \
        *) echo "Unsupported architecture for ripgrep: ${ARCH}" && exit 1 ;; \
    esac && \
    curl -LO "https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep-14.1.1-${RIPGREP_ARCH}.tar.gz" && \
    tar -xzf "ripgrep-14.1.1-${RIPGREP_ARCH}.tar.gz" && \
    mv "ripgrep-14.1.1-${RIPGREP_ARCH}/rg" /usr/local/bin/ && \
    rm -rf ripgrep-14.1.1-*

# Install fd
RUN ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
        amd64) FD_ARCH='x86_64-unknown-linux-musl' ;; \
        arm64) FD_ARCH='aarch64-unknown-linux-musl' ;; \
        *) echo "Unsupported architecture for fd: ${ARCH}" && exit 1 ;; \
    esac && \
    curl -LO "https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-v10.2.0-${FD_ARCH}.tar.gz" && \
    tar -xzf "fd-v10.2.0-${FD_ARCH}.tar.gz" && \
    mv "fd-v10.2.0-${FD_ARCH}/fd" /usr/local/bin/ && \
    rm -rf fd-v10.2.0-*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh

# Install ast-grep
RUN ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
        amd64) AST_GREP_ARCH='x86_64-unknown-linux-gnu' ;; \
        arm64) AST_GREP_ARCH='aarch64-unknown-linux-gnu' ;; \
        *) echo "Unsupported architecture for ast-grep: ${ARCH}" && exit 1 ;; \
    esac && \
    curl -LO "https://github.com/ast-grep/ast-grep/releases/download/0.39.2/app-${AST_GREP_ARCH}.zip" && \
    unzip "app-${AST_GREP_ARCH}.zip" && \
    mv ast-grep /usr/local/bin/ && \
    rm -rf app-*

# Install Rust as root
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# Clean package cache
RUN apt-get autoremove -y && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /workspace

# Set shell to bash
SHELL ["/bin/bash", "-c"]

CMD ["claude", "--dangerously-skip-permissions"]
