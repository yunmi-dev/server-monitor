# Build stage
FROM debian:bookworm-slim AS builder

# Install Flutter dependencies
RUN apt-get update && apt-get install -y curl git unzip xz-utils zip libglu1-mesa

# Clone the flutter repo
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter

# Set flutter path
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Run flutter doctor
RUN flutter doctor

# Enable flutter web
RUN flutter channel stable
RUN flutter upgrade
RUN flutter config --enable-web

# Copy files to container and build
WORKDIR /app
COPY flutter_client .
RUN flutter build web

# Runtime stage
FROM nginx:alpine
COPY --from=builder /app/build/web /usr/share/nginx/html