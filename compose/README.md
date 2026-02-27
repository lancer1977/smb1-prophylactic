# Docker Compose Configurations

This directory contains various Docker Compose configurations for different deployment scenarios of the SMB Prophylactic service.

## Available Configurations

### 1. Development Environment (`docker-compose.dev.yml`)

**Purpose**: Local development and testing with hot reloading and debugging capabilities.

**Features**:
- Volume mounts for source code (hot reloading)
- Development server with debugging enabled
- Development monitoring and logging services
- Web interface for configuration
- Debug logging enabled

**Usage**:
```bash
docker-compose -f compose/docker-compose.dev.yml up -d
```

**Services**:
- `smb-prophylactic-dev`: Main SMB service with development configuration
- `smb-monitor-dev`: Node exporter for monitoring
- `smb-logger-dev`: Fluent Bit for log aggregation
- `smb-web-config-dev`: Nginx web interface for configuration

### 2. Production Environment (`docker-compose.prod.yml`)

**Purpose**: Full production deployment with monitoring, alerting, and centralized logging.

**Features**:
- Multi-stage builds for optimization
- Security hardening (non-root execution, read-only filesystems)
- Resource limits and monitoring
- Prometheus monitoring stack
- Grafana dashboard
- Centralized logging with Loki
- Alerting with AlertManager

**Usage**:
```bash
docker-compose -f compose/docker-compose.prod.yml up -d
```

**Services**:
- `smb-prophylactic-prod`: Main SMB service with production configuration
- `smb-prometheus-prod`: Prometheus monitoring server
- `smb-alertmanager-prod`: Alert management
- `smb-loki-prod`: Centralized logging
- `smb-promtail-prod`: Log shipping agent
- `smb-grafana-prod`: Monitoring dashboard

### 3. Minimal Setup (`docker-compose.minimal.yml`)

**Purpose**: Lightweight configuration for resource-constrained environments or quick testing.

**Features**:
- Essential services only
- Minimal resource usage
- Basic health monitoring
- Simplified configuration

**Usage**:
```bash
docker-compose -f compose/docker-compose.minimal.yml up -d
```

**Services**:
- `smb-prophylactic-minimal`: Main SMB service with minimal configuration
- `smb-health-check`: Basic health monitoring

### 4. GitHub Container Registry (`docker-compose.ghcr.yml`)

**Purpose**: Optimized for deployment from GitHub Container Registry with multi-platform support.

**Features**:
- Pre-built images from GHCR
- Multi-platform build support
- Security scanning integration
- Automated backup service
- Registry authentication helper
- Build cache optimization

**Usage**:
```bash
docker-compose -f compose/docker-compose.ghcr.yml up -d
```

**Services**:
- `smb-prophylactic-ghcr`: Main SMB service using GHCR images
- `ghcr-builder`: Docker-in-Docker for multi-platform builds
- `ghcr-auth-helper`: Registry authentication
- `ghcr-security-scanner`: Automated security scanning
- `ghcr-node-exporter`: Node metrics
- `ghcr-backup-service`: Automated backups

## Environment Variables

### Common Variables
- `ENVIRONMENT`: Environment type (development, production)
- `DEBUG`: Enable debug mode (true/false)
- `LOG_LEVEL`: Logging level (debug, info, error)
- `SAMBA_DEBUG_LEVEL`: Samba debug level (1-10)

### GHCR Specific
- `GHCR_USERNAME`: GitHub username for registry access
- `GHCR_TOKEN`: GitHub personal access token
- `CONTAINER_REGISTRY`: Registry URL
- `IMAGE_TAG`: Image tag to use

## Storage Volumes

Each configuration uses named volumes for persistent storage:

- **Development**: `dev-storage`, `dev-logs`
- **Production**: `prod-storage`, `prod-logs`, `prometheus-data`, `grafana-data`
- **Minimal**: `minimal-storage`
- **GHCR**: `ghcr-storage`, `ghcr-logs`, `ghcr-backups`

## Networking

Each configuration uses isolated bridge networks:
- Development: `172.20.0.0/16`
- Production: `172.21.0.0/16`
- Minimal: `172.22.0.0/16`
- GHCR: `172.23.0.0/16`

## Security Features

### Production & GHCR Configurations
- Non-root user execution (`user: "1000:1000"`)
- Read-only filesystems where appropriate
- No new privileges security option
- Resource limits and reservations
- Health checks and restart policies

### Development Configuration
- Debug mode enabled for troubleshooting
- Volume mounts for hot reloading
- Development tools and monitoring

## Monitoring and Logging

### Development
- Node exporter on port 9100
- Fluent Bit for log aggregation
- Web interface on port 8080

### Production
- Prometheus on port 9090
- Grafana on port 3000
- AlertManager on port 9093
- Loki on port 3100
- Centralized log aggregation

### GHCR
- Node exporter on port 9100
- Automated security scanning
- Backup service with daily snapshots

## Deployment Notes

### Prerequisites
- Docker and Docker Compose installed
- Proper permissions for volume mounts
- Network access for required ports

### Configuration Files
- Main configuration: `../config/smb.conf`
- Scripts: `../scripts/`
- Environment variables: Use `.env` files or environment variables

### Port Conflicts
Ensure the following ports are available:
- **SMB**: 445 (TCP), 139 (TCP), 137 (UDP), 138 (UDP)
- **Monitoring**: 9090, 9093, 3000, 3100, 9100
- **Development**: 8080, 24224, 2020

### Health Checks
All configurations include health checks using `nc` (netcat) to verify SMB service availability on port 445.

## Troubleshooting

### Common Issues
1. **Port conflicts**: Check for existing services on required ports
2. **Permission issues**: Ensure proper file permissions for mounted volumes
3. **Network issues**: Verify Docker network connectivity
4. **Resource limits**: Adjust CPU/memory limits based on available resources

### Debug Commands
```bash
# View logs for a specific service
docker-compose -f compose/docker-compose.prod.yml logs smb-prophylactic-prod

# Check service health
docker-compose -f compose/docker-compose.prod.yml ps

# Restart a specific service
docker-compose -f compose/docker-compose.prod.yml restart smb-prophylactic-prod

# Scale services
docker-compose -f compose/docker-compose.prod.yml scale smb-prophylactic-prod=2
```

## Security Considerations

### Network Security
- Use firewall rules to restrict access to SMB ports
- Consider VPN or network segmentation for production deployments
- Monitor network traffic for suspicious activity

### Container Security
- Keep base images updated
- Use minimal base images where possible
- Implement proper user permissions
- Regular security scanning of images

### Data Security
- Encrypt sensitive configuration files
- Use proper backup strategies
- Implement access controls for storage volumes
- Regular security audits and monitoring