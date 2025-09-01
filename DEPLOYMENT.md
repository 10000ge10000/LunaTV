# 10000TV Private Deployment Guide

This guide provides complete instructions for privately deploying 10000TV without any dependencies on external repositories.

## Quick Start

### Step 1: Build the Docker Image

```bash
# Clone or download the source code
git clone <your-private-repository>
cd 10000TV

# Build the Docker image
docker build -t 10000tv:latest .
```

### Step 2: Choose Your Storage Backend

Copy the appropriate docker-compose configuration:

```bash
# Copy the example compose file
cp docker-compose.example.yml docker-compose.yml

# Edit the configuration
nano docker-compose.yml
```

### Step 3: Configure Environment

```bash
# Copy environment template
cp .env.example .env.local

# Edit your configuration
nano .env.local
```

Key configuration options:
- `USERNAME` and `PASSWORD`: Admin credentials
- `NEXT_PUBLIC_STORAGE_TYPE`: Choose from `kvrocks`, `redis`, or `upstash`
- Storage connection strings based on your choice

### Step 4: Deploy

```bash
# Start the services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

## Storage Options

### Kvrocks (Recommended)
- Best performance and reliability
- Built-in persistence
- Low memory usage

### Redis
- Good performance
- Make sure to enable persistence
- Higher memory usage

### Upstash
- Managed cloud Redis
- No local storage needed
- Requires external service

## Security Notes

1. **Change Default Credentials**: Always change the default admin username and password
2. **Use Strong Passwords**: Use complex passwords for production
3. **Network Security**: Consider using reverse proxy with SSL
4. **Firewall**: Restrict access to port 3000 if needed

## Maintenance

### Backup Data
```bash
# For Kvrocks/Redis deployments
docker-compose exec 10000tv-kvrocks redis-cli BGSAVE
```

### Update Application
```bash
# Rebuild image with new code
docker build -t 10000tv:latest .

# Restart services
docker-compose down
docker-compose up -d
```

### Check Logs
```bash
# Application logs
docker-compose logs 10000tv-core

# Database logs  
docker-compose logs 10000tv-kvrocks
```

## Troubleshooting

### Common Issues

1. **Port Already in Use**
   - Change port mapping in docker-compose.yml: `"8080:3000"`

2. **Storage Connection Failed**
   - Check storage service is running: `docker-compose ps`
   - Verify connection string in environment

3. **Build Failed**
   - Ensure Docker has sufficient resources
   - Check for syntax errors in configuration files

4. **Access Denied**
   - Verify username/password configuration
   - Check browser console for errors

### Performance Optimization

1. **Resource Limits**
   ```yaml
   services:
     10000tv-core:
       deploy:
         resources:
           limits:
             memory: 1G
             cpus: '0.5'
   ```

2. **Cache Configuration**
   - Adjust `cache_time` in configuration file
   - Monitor storage usage

For additional support, refer to the configuration documentation in the source code.