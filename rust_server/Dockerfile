# Dockerfile for development environment
FROM rust:1.82-slim-bookworm

# Set CARGO_HOME for caching
ENV CARGO_HOME=/usr/local/cargo

# Install build dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    libpq-dev \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

# Install latest version of cargo-watch
RUN cargo install cargo-watch --version=8.1.2 --locked
RUN cargo install sqlx-cli --no-default-features --features postgres

# Default command for development
CMD ["cargo", "watch", "-x", "run"]