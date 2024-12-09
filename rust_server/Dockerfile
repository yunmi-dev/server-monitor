# Build stage
FROM rust:latest as builder
WORKDIR /app
COPY rust_server .
RUN cargo build --release

# Runtime stage
FROM debian:bookworm-slim
WORKDIR /app
COPY --from=builder /app/target/release/rust_server .
COPY rust_server/migrations ./migrations

# Install necessary runtime dependencies
RUN apt-get update && apt-get install -y libpq5 \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 8080
CMD ["./rust_server"]