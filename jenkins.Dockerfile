FROM jenkins/jenkins:lts

USER root

# Install necessary packages
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    docker.io \
    git \
    xz-utils \
    build-essential \
    pkg-config \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install cargo tools
RUN cargo install cargo-watch --version=8.1.2 --locked
RUN cargo install sqlx-cli --no-default-features --features postgres

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}"
RUN flutter doctor
RUN flutter precache

# Docker group settings
RUN groupadd docker || true
RUN usermod -aG docker jenkins

USER jenkins