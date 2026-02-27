# SMB Prophylactic - Dockerfile
# Multi-stage build for optimized container size and security

# Build stage
FROM ubuntu:22.04 AS builder

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libacl1-dev \
    libattr1-dev \
    libblkid-dev \
    libgnutls28-dev \
    libjson-perl \
    libreadline-dev \
    python3 \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Download and build Samba from source for better control
RUN apt-get update && apt-get install -y \
    samba \
    samba-common-bin \
    cifs-utils \
    curl \
    wget \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Runtime stage
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV Samba_VERSION=4.19.5

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    samba \
    samba-common-bin \
    cifs-utils \
    curl \
    wget \
    nano \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -r samba \
    && useradd -r -g samba samba

# Create necessary directories
RUN mkdir -p /etc/samba \
    && mkdir -p /var/log/samba \
    && mkdir -p /srv/smb-bridge \
    && mkdir -p /mnt/legacy-smb \
    && mkdir -p /opt/smb-prophylactic/scripts

# Copy configuration and scripts
COPY --chown=samba:samba config/smb.conf /etc/samba/smb.conf
COPY --chown=samba:samba scripts/ /opt/smb-prophylactic/scripts/

# Make scripts executable
RUN chmod +x /opt/smb-prophylactic/scripts/*.sh

# Create health check script
COPY --chown=samba:samba scripts/health-check.sh /usr/local/bin/health-check.sh
RUN chmod +x /usr/local/bin/health-check.sh

# Set up log rotation
RUN echo "/var/log/samba/*.log {\n    daily\n    missingok\n    rotate 30\n    compress\n    delaycompress\n    notifempty\n    create 644 samba samba\n}" > /etc/logrotate.d/samba

# Expose SMB ports
EXPOSE 445 139

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /usr/local/bin/health-check.sh

# Set working directory
WORKDIR /opt/smb-prophylactic

# Set entrypoint
ENTRYPOINT ["/opt/smb-prophylactic/scripts/start-bridge.sh"]

# Default command
CMD ["start"]