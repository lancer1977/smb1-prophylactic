# SMB Prophylactic

**SMB Protocol Bridge & Translator**

A Docker-based solution that bridges legacy SMB1 servers to modern networks by transparently translating between SMB1 and SMB2+ protocols.

## 🚀 Quick Start

```bash
# Clone and setup
git clone git@github.com:lancer1977/smb1-prophylactic.git
cd smb-prophylactic

# Build and run
docker-compose up -d

# Test connection
smbclient -L localhost -N
```

## 📋 Problem Solved

Many organizations have legacy systems that only support SMB1, but modern security standards require SMB2+ due to SMB1's known vulnerabilities. This container acts as a protocol translator, allowing:

- **Legacy SMB1 servers** to be accessed by **modern SMB2+ clients**
- **Secure protocol translation** without exposing vulnerable SMB1 directly
- **Network isolation** and **containerized deployment**

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────────┐    ┌─────────────────┐
│   Legacy SMB1   │    │   SMB Prophylactic  │    │  Modern SMB2+   │
│   Server        │◄──►│   (Protocol Bridge) │◄──►│   Clients       │
│   (192.168.0.106)│    │                     │    │                 │
└─────────────────┘    └─────────────────────┘    └─────────────────┘
         SMB1                    SMB1/SMB2+               SMB2+
```

## 📁 Project Structure

```
smb-prophylactic/
├── 🐳 Docker Configuration
│   ├── Dockerfile              # Main container definition
│   ├── docker-compose.yml      # Development & production setup
│   └── docker-compose.override.yml  # Local overrides
│
├── ⚙️ Configuration
│   ├── config/smb.conf         # Samba configuration
│   ├── scripts/start-bridge.sh # Container startup script
│   └── scripts/health-check.sh # Health monitoring
│
├── 🚀 GitHub Actions
│   └── .github/workflows/
│       ├── build-and-push.yml  # Container build & registry push
│       ├── deploy.yml          # Deployment automation
│       └── security-scan.yml   # Security scanning
│
├── 📚 Documentation
│   ├── docs/
│   │   ├── README.md           # User documentation
│   │   ├── DEVELOPMENT.md      # Development guide
│   │   └── DEPLOYMENT.md       # Deployment guide
│   └── examples/               # Usage examples
│
├── 🧪 Testing
│   ├── tests/
│   │   ├── integration/        # Integration tests
│   │   └── unit/              # Unit tests
│   └── test-compose.yml        # Testing configuration
│
└── 📋 Project Files
    ├── README.md               # This file
    ├── LICENSE                 # MIT License
    └── .gitignore             # Git ignore rules
```

## 🛠️ Installation

### Prerequisites

- Docker & Docker Compose
- Git
- Network access to legacy SMB1 server

### Quick Setup

1. **Clone the repository:**
   ```bash
   git clone git@github.com:lancer1977/smb1-prophylactic.git
   cd smb-prophylactic
   ```

2. **Configure for your environment:**
   ```bash
   # Edit the configuration
   cp config/smb.conf.example config/smb.conf
   cp scripts/start-bridge.sh.example scripts/start-bridge.sh
   
   # Update with your legacy server details
   nano scripts/start-bridge.sh
   ```

3. **Build and start:**
   ```bash
   docker-compose up -d
   ```

4. **Verify deployment:**
   ```bash
   docker-compose logs -f
   smbclient -L localhost -N
   ```

## ⚙️ Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LEGACY_SERVER` | `192.168.0.106` | IP/hostname of legacy SMB1 server |
| `LEGACY_SHARE` | `share` | Share name on legacy server |
| `BRIDGE_PORT` | `445` | Port to expose on bridge |
| `TZ` | `UTC` | Timezone for logs |

### Samba Configuration

The `config/smb.conf` file controls:
- Protocol versions supported
- Authentication methods
- Performance tuning
- Security settings

## 🔒 Security

### Security Features

- **Network Isolation:** Container provides security boundary
- **Protocol Translation:** No direct SMB1 exposure to network
- **Guest Access:** Configurable authentication
- **Logging:** Comprehensive audit trails
- **Resource Limits:** Prevents resource exhaustion

### Security Considerations

⚠️ **Important:** This bridge enables access to legacy systems. Ensure:

1. **Network Segmentation:** Place bridge in appropriate network zone
2. **Access Control:** Configure proper authentication
3. **Monitoring:** Monitor logs for suspicious activity
4. **Updates:** Keep container and dependencies updated

## 🚀 Deployment

### Docker Compose

```bash
# Development
docker-compose up -d

# Production
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# With custom configuration
docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d
```

### Kubernetes

```bash
# Deploy to Kubernetes
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

### Docker Swarm

```bash
# Deploy to Docker Swarm
docker stack deploy -c docker-stack.yml smb-prophylactic
```

## 🧪 Testing

### Integration Tests

```bash
# Run integration tests
docker-compose -f test-compose.yml up --abort-on-container-exit
```

### Manual Testing

```bash
# Test SMB connection
smbclient -L localhost -N

# Test file operations
smbclient //localhost/bridge-share -N

# Test with credentials
smbclient -L localhost -U username%password
```

## 📊 Monitoring

### Health Checks

The container includes health checks that verify:
- Samba services are running
- Legacy server connection is active
- File system mounts are accessible

### Metrics

Monitor these key metrics:
- **Connection Count:** Number of active SMB connections
- **Response Time:** SMB operation latency
- **Error Rate:** Failed connection attempts
- **Resource Usage:** CPU, memory, network

### Logs

```bash
# View container logs
docker-compose logs -f

# View specific service logs
docker-compose logs smbd
docker-compose logs nmbd
```

## 🐛 Troubleshooting

### Common Issues

1. **Connection Refused**
   - Check legacy server IP and share name
   - Verify network connectivity
   - Check firewall rules

2. **Authentication Failed**
   - Verify credentials in configuration
   - Check Samba configuration
   - Test with guest access first

3. **Performance Issues**
   - Check network bandwidth
   - Verify resource limits
   - Review Samba performance settings

### Debug Mode

```bash
# Enable debug logging
docker-compose up -d --build

# Check container status
docker-compose ps

# Inspect container
docker inspect smb-prophylactic_smbd_1
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **kat-coder-pro** for the original SMB1 Prophylactic concept and implementation
- Samba Project for the underlying SMB implementation
- Docker community for containerization technology
- Security researchers for SMB1 vulnerability disclosures

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/lancer1977/smb1-prophylactic/issues)
- **Documentation:** [Wiki](https://github.com/lancer1977/smb1-prophylactic/wiki)
- **Discussions:** [GitHub Discussions](https://github.com/lancer1977/smb1-prophylactic/discussions)

---

**Made with ❤️ for legacy system integration**

## 📖 Documentation
Detailed documentation can be found in the following sections:
- [Feature Index](./docs/features/README.md)
- [Core Capabilities](./docs/features/core-capabilities.md)
