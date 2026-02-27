# SMB Prophylactic Deployment Guide

This guide covers various deployment options for the SMB Prophylactic container.

## 🚀 Quick Deployment

### Docker Compose (Recommended)

```bash
# Clone the repository
git clone git@github.com:lancer1977/smb1-prophylactic.git
cd smb-prophylactic

# Configure environment variables
cp .env.example .env
nano .env

# Start the service
docker-compose up -d

# Verify deployment
docker-compose ps
docker-compose logs -f
```

### Docker Run

```bash
# Run directly with Docker
docker run -d \
  --name smb-prophylactic \
  --restart unless-stopped \
  -p 445:445 \
  -p 139:139 \
  -e LEGACY_SERVER=192.168.0.106 \
  -e LEGACY_SHARE=share \
  -v /path/to/smb.conf:/etc/samba/smb.conf:ro \
  ghcr.io/lancer1977/smb1-prophylactic:latest
```

## 🏗️ Production Deployment

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LEGACY_SERVER` | `192.168.0.106` | IP/hostname of legacy SMB1 server |
| `LEGACY_SHARE` | `share` | Share name on legacy server |
| `TZ` | `UTC` | Timezone for logs |
| `SMB_WORKGROUP` | `WORKGROUP` | SMB workgroup name |
| `SMB_DEBUG_LEVEL` | `2` | Samba debug level (0-10) |

### Configuration Files

#### Environment File (`.env`)
```bash
# SMB Prophylactic Configuration
LEGACY_SERVER=192.168.0.106
LEGACY_SHARE=share
TZ=America/New_York
SMB_WORKGROUP=WORKGROUP
SMB_DEBUG_LEVEL=2
```

#### Docker Compose Override (`.docker-compose.override.yml`)
```yaml
version: '3.8'
services:
  smb-prophylactic:
    environment:
      - TZ=America/New_York
      - LEGACY_SERVER=your-legacy-server
      - LEGACY_SHARE=your-share-name
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1G
        reservations:
          cpus: '1.0'
          memory: 512M
```

## ☸️ Kubernetes Deployment

### Prerequisites

- Kubernetes cluster (v1.20+)
- kubectl configured
- Container registry access

### Deployment Steps

1. **Create namespace:**
   ```bash
   kubectl create namespace smb-prophylactic
   ```

2. **Apply configurations:**
   ```bash
   kubectl apply -f k8s/
   ```

3. **Verify deployment:**
   ```bash
   kubectl get pods -n smb-prophylactic
   kubectl get services -n smb-prophylactic
   ```

### Kubernetes Manifests

#### Deployment (`k8s/deployment.yaml`)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: smb-prophylactic
  namespace: smb-prophylactic
  labels:
    app: smb-prophylactic
spec:
  replicas: 1
  selector:
    matchLabels:
      app: smb-prophylactic
  template:
    metadata:
      labels:
        app: smb-prophylactic
    spec:
      containers:
      - name: smb-prophylactic
        image: ghcr.io/lancer1977/smb1-prophylactic:latest
        ports:
        - containerPort: 445
          protocol: TCP
        - containerPort: 139
          protocol: TCP
        env:
        - name: LEGACY_SERVER
          value: "192.168.0.106"
        - name: LEGACY_SHARE
          value: "share"
        - name: TZ
          value: "UTC"
        resources:
          limits:
            cpu: "1000m"
            memory: "512Mi"
          requests:
            cpu: "500m"
            memory: "256Mi"
        livenessProbe:
          httpGet:
            path: /health
            port: 445
          initialDelaySeconds: 60
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /ready
            port: 445
          initialDelaySeconds: 30
          periodSeconds: 10
        volumeMounts:
        - name: smb-config
          mountPath: /etc/samba/smb.conf
          subPath: smb.conf
      volumes:
      - name: smb-config
        configMap:
          name: smb-prophylactic-config
```

#### Service (`k8s/service.yaml`)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: smb-prophylactic
  namespace: smb-prophylactic
  labels:
    app: smb-prophylactic
spec:
  selector:
    app: smb-prophylactic
  ports:
  - name: smb
    protocol: TCP
    port: 445
    targetPort: 445
  - name: netbios
    protocol: TCP
    port: 139
    targetPort: 139
  type: LoadBalancer
```

#### ConfigMap (`k8s/configmap.yaml`)
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: smb-prophylactic-config
  namespace: smb-prophylactic
data:
  smb.conf: |
    [global]
    workgroup = WORKGROUP
    server string = SMB Prophylactic Bridge
    netbios name = smb-prophylactic
    server role = standalone server
    security = user
    map to guest = bad user
    server min protocol = NT1
    server max protocol = SMB3
    client min protocol = CORE
    client max protocol = NT1
    socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=1048576 SO_SNDBUF=1048576
    log level = 2
    log file = /var/log/samba/%m.log
    max log size = 1000
    load printers = no
    printing = bsd
    printcap name = /dev/null
    disable spoolss = yes
    guest account = nobody
    map to guest = bad user
    vfs objects = shadow_copy2

    [bridge-share]
    path = /srv/smb-bridge
    browseable = yes
    read only = no
    guest ok = yes
    create mask = 0644
    directory mask = 0755
    force user = samba
    force group = samba
```

## 🐳 Docker Swarm Deployment

### Prerequisites

- Docker Swarm cluster
- Docker Compose file

### Deployment Steps

1. **Initialize Swarm (if not already done):**
   ```bash
   docker swarm init
   ```

2. **Deploy stack:**
   ```bash
   docker stack deploy -c docker-stack.yml smb-prophylactic
   ```

3. **Verify deployment:**
   ```bash
   docker service ls
   docker service ps smb-prophylactic_smb-prophylactic
   ```

### Docker Stack File (`docker-stack.yml`)
```yaml
version: '3.8'

services:
  smb-prophylactic:
    image: ghcr.io/lancer1977/smb1-prophylactic:latest
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
      placement:
        constraints:
          - node.role == worker
    ports:
      - "445:445"
      - "139:139"
    environment:
      - LEGACY_SERVER=192.168.0.106
      - LEGACY_SHARE=share
      - TZ=UTC
    volumes:
      - smb-logs:/var/log/samba
      - smb-data:/srv/smb-bridge
      - smb-cache:/var/lib/samba

volumes:
  smb-logs:
  smb-data:
  smb-cache:
```

## 🔒 Security Considerations

### Network Security

1. **Firewall Rules:**
   ```bash
   # Allow SMB traffic only from trusted networks
   ufw allow from 192.168.0.0/24 to any port 445
   ufw allow from 192.168.0.0/24 to any port 139
   ```

2. **VPN Access:**
   - Deploy behind VPN for remote access
   - Use site-to-site VPN for branch offices

3. **Network Segmentation:**
   - Place in DMZ or isolated network segment
   - Use VLANs for additional isolation

### Authentication Security

1. **Enable Authentication:**
   ```ini
   # In smb.conf
   security = user
   encrypt passwords = yes
   
   [bridge-share]
   valid users = @smbusers
   read only = no
   ```

2. **User Management:**
   ```bash
   # Create Samba users
   docker exec smb-prophylactic smbpasswd -a username
   
   # Create user groups
   groupadd smbusers
   usermod -a -G smbusers username
   ```

### Container Security

1. **Run as Non-Root:**
   ```dockerfile
   USER samba
   ```

2. **Read-Only Filesystem:**
   ```yaml
   # In docker-compose.yml
   read_only: true
   tmpfs:
     - /tmp
     - /var/run
   ```

3. **Security Scanning:**
   - Enable GitHub Actions security scanning
   - Regular vulnerability assessments

## 📊 Monitoring and Logging

### Health Checks

The container includes built-in health checks:
- Samba services status
- Legacy share mount status
- Bridge share accessibility

### Log Monitoring

```bash
# View container logs
docker-compose logs -f smb-prophylactic

# View Samba logs
docker exec smb-prophylactic tail -f /var/log/samba/smbd.log

# View health check logs
docker exec smb-prophylactic tail -f /var/log/smb-health.log
```

### Metrics Collection

1. **Prometheus Integration:**
   ```yaml
   # Add to docker-compose.yml
   labels:
     - "prometheus.io/scrape=true"
     - "prometheus.io/port=9090"
     - "prometheus.io/path=/metrics"
   ```

2. **Grafana Dashboards:**
   - Create dashboards for SMB metrics
   - Monitor connection counts and response times

### Alerting

Set up alerts for:
- Service downtime
- High error rates
- Resource exhaustion
- Authentication failures

## 🚨 Troubleshooting

### Common Issues

1. **Connection Refused:**
   - Check firewall rules
   - Verify port bindings
   - Check container health

2. **Authentication Failed:**
   - Verify credentials
   - Check Samba configuration
   - Test with guest access

3. **Performance Issues:**
   - Check network bandwidth
   - Verify resource limits
   - Review Samba performance settings

### Debug Commands

```bash
# Test SMB connection
docker exec smb-prophylactic smbclient -L localhost -N

# Check mount status
docker exec smb-prophylactic df -h

# Test legacy server connectivity
docker exec smb-prophylactic ping 192.168.0.106

# Check Samba configuration
docker exec smb-prophylactic testparm
```

### Log Analysis

```bash
# Search for errors
docker exec smb-prophylactic grep -i error /var/log/samba/*.log

# Check authentication logs
docker exec smb-prophylactic grep -i auth /var/log/samba/*.log

# Monitor real-time logs
docker exec smb-prophylactic tail -f /var/log/samba/*.log
```

## 🔄 Backup and Recovery

### Configuration Backup

```bash
# Backup configuration
tar -czf smb-prophylactic-backup.tar.gz \
  config/ \
  scripts/ \
  docker-compose.yml \
  .env
```

### Data Backup

```bash
# Backup Samba data
docker exec smb-prophylactic tar -czf /tmp/samba-data.tar.gz /var/lib/samba

# Copy backup to host
docker cp smb-prophylactic:/tmp/samba-data.tar.gz .
```

### Recovery Procedures

1. **Container Recovery:**
   ```bash
   # Stop and remove container
   docker-compose down
   
   # Restore from backup
   tar -xzf smb-prophylactic-backup.tar.gz
   
   # Restart
   docker-compose up -d
   ```

2. **Configuration Recovery:**
   ```bash
   # Restore configuration
   docker cp config/smb.conf smb-prophylactic:/etc/samba/smb.conf
   
   # Restart Samba
   docker exec smb-prophylactic smbcontrol smbd reload-config
   ```

## 📈 Scaling

### Horizontal Scaling

For high availability:
1. Deploy multiple instances
2. Use load balancer
3. Implement shared storage

### Vertical Scaling

For performance:
1. Increase CPU/memory limits
2. Optimize Samba configuration
3. Use faster storage

## 🧪 Testing

### Integration Tests

```bash
# Run integration tests
docker-compose -f test-compose.yml up --abort-on-container-exit

# Manual testing
docker exec smb-prophylactic /opt/smb-prophylactic/scripts/start-bridge.sh test
```

### Load Testing

```bash
# Install load testing tools
docker run --rm -it \
  --network smb-prophylactic_smb-network \
  jordi/ab \
  ab -n 1000 -c 10 http://smb-prophylactic:445/
```

This deployment guide provides comprehensive instructions for deploying SMB Prophylactic in various environments while maintaining security and performance standards.