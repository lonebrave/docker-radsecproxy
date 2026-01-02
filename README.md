# RadSecProxy Docker Container

A multi-stage Docker container for [radsecproxy](https://github.com/radsecproxy/radsecproxy) built on Alpine Linux 3.23.2. This container provides a lightweight, secure RADIUS proxy with TLS support (RadSec).

## Features

- Multi-stage build for minimal image size
- Configurable radsecproxy version via build arguments
- Runs as non-root user for enhanced security
- Alpine Linux 3.23.2 base for small footprint
- Docker Compose support for easy deployment
- Health checks included

## Prerequisites

- Docker 20.10 or later
- Docker Compose 2.0 or later (if using compose)
- Basic understanding of RADIUS and RadSec

## Quick Start

### Using Docker Compose (Recommended)

1. **Clone or create the project structure:**

```bash
mkdir radsecproxy-docker && cd radsecproxy-docker
# Copy Dockerfile and docker-compose.yml to this directory
```

2. **Create the configuration directory:**

```bash
mkdir -p config/certs
```

3. **Add your configuration file:**

Create `config/radsecproxy.conf` with your settings. Example:

```conf
# Example radsecproxy.conf
LogLevel        3
LogDestination  file:///var/log/radsecproxy/radsecproxy.log

# TLS configuration
tls default {
    CACertificateFile    /etc/radsecproxy/certs/ca.pem
    CertificateFile      /etc/radsecproxy/certs/server-cert.pem
    CertificateKeyFile   /etc/radsecproxy/certs/server-key.pem
}

# Client configuration
client 192.168.1.0/24 {
    type    udp
    secret  testing123
}

# Server configuration
server radius-server {
    type    tls
    host    radius.example.com
    port    2083
    secret  radsec
}

# Realm configuration
realm * {
    server  radius-server
}
```

4. **Add your TLS certificates:**

Place your certificates in `config/certs/`:
- `ca.pem` - Certificate Authority certificate
- `server-cert.pem` - Server certificate
- `server-key.pem` - Server private key

5. **Start the container:**

```bash
docker compose up -d
```

6. **View logs:**

```bash
docker compose logs -f radsecproxy
```

### Using Docker Build Directly

1. **Build the image:**

```bash
# Build with default version (1.11.2)
docker build -t radsecproxy:latest .

# Build with specific version
docker build --build-arg RADSECPROXY_VERSION=1.9.2 -t radsecproxy:1.9.2 .
```

2. **Run the container:**

```bash
docker run -d \
  --name radsecproxy \
  -v $(pwd)/config/radsecproxy.conf:/etc/radsecproxy.conf:ro \
  -v $(pwd)/config/certs:/etc/radsecproxy/certs:ro \
  -p 1812:1812/udp \
  -p 1813:1813/udp \
  -p 2083:2083/tcp \
  radsecproxy:latest
```

## Configuration

### Build Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `RADSECPROXY_VERSION` | `1.11.2` | Git tag, branch, or commit to build |

### Exposed Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 1812 | UDP | RADIUS authentication |
| 1813 | UDP | RADIUS accounting |
| 2083 | TCP | RadSec (RADIUS over TLS) |

### Volumes

| Path | Description |
|------|-------------|
| `/etc/radsecproxy.conf` | Main configuration file (read-only) |
| `/etc/radsecproxy/certs` | TLS certificates directory (read-only) |
| `/var/log/radsecproxy` | Log files directory |

## Building Different Versions

To build a specific version of radsecproxy, modify the `RADSECPROXY_VERSION` in `docker-compose.yml`:

```yaml
args:
  RADSECPROXY_VERSION: 1.9.2  # Change to desired version
```

Or use the command line:

```bash
docker compose build --build-arg RADSECPROXY_VERSION=1.9.2
```

Available versions can be found at: https://github.com/radsecproxy/radsecproxy/tags

## Management Commands

### Docker Compose

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# Restart services
docker compose restart

# Rebuild image
docker compose build --no-cache

# View running containers
docker compose ps
```

### Docker

```bash
# Start container
docker start radsecproxy

# Stop container
docker stop radsecproxy

# View logs
docker logs -f radsecproxy

# Restart container
docker restart radsecproxy

# Execute command in container
docker exec -it radsecproxy /bin/sh

# Remove container
docker rm radsecproxy
```

## Troubleshooting

### Check if radsecproxy is running

```bash
docker compose exec radsecproxy ps aux
```

### View detailed logs

```bash
docker compose logs --tail=100 -f radsecproxy
```

### Access container shell

```bash
docker compose exec radsecproxy /bin/sh
```

### Test RADIUS connectivity

From the host or another container:

```bash
# Test with radtest (requires freeradius-utils)
radtest username password localhost:1812 0 testing123
```

### Common Issues

**Issue: Container exits immediately**
- Check your `radsecproxy.conf` syntax
- Verify certificate paths are correct
- Check logs: `docker compose logs radsecproxy`

**Issue: Cannot connect to RADIUS ports**
- Verify ports are not already in use: `netstat -tuln | grep -E '1812|1813|2083'`
- Check firewall rules
- Ensure port mappings in compose file match your needs

**Issue: TLS/SSL errors**
- Verify certificate files exist and have correct permissions
- Check certificate validity dates
- Ensure CA certificate matches server certificate

**Issue: Permission denied errors**
- Ensure mounted volumes have appropriate permissions
- The container runs as user `radsecproxy` (non-root)

## Security Considerations

- The container runs as a non-root user (`radsecproxy`)
- Configuration and certificates are mounted read-only
- Keep radsecproxy version up to date for security patches
- Use strong secrets in your configuration
- Protect your TLS private keys with appropriate file permissions
- Consider using Docker secrets for sensitive data in production

## Project Structure

```
radsecproxy-docker/
├── Dockerfile              # Multi-stage build definition
├── docker-compose.yml      # Compose configuration
├── README.md              # This file
└── config/
    ├── radsecproxy.conf   # Your configuration file
    └── certs/             # TLS certificates
        ├── ca.pem
        ├── server-cert.pem
        └── server-key.pem
```

## Additional Resources

- [RadSecProxy Documentation](https://radsecproxy.github.io/)
- [RadSecProxy GitHub](https://github.com/radsecproxy/radsecproxy)
- [RADIUS RFC 2865](https://tools.ietf.org/html/rfc2865)
- [RadSec RFC 6614](https://tools.ietf.org/html/rfc6614)

## License

This Docker configuration is provided as-is. RadSecProxy itself is licensed under the BSD 3-Clause License. See the [radsecproxy repository](https://github.com/radsecproxy/radsecproxy) for details.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.
