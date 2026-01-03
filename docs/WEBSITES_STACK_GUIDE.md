# Websites Stack Guide

This guide explains how to add custom websites and web applications to the WEBSITES stack.

## Overview

The WEBSITES stack is designed to host your custom websites, web applications, and personal web services. Each website runs in its own container with network isolation and automatic updates via the infrastructure watchtower.

## Quick Start

### 1. Prepare Your Website Files

Ensure your website files are ready:
- **Static websites**:** HTML, CSS, JS files
- **Node.js apps**:** Include `package.json` and dependencies
- **PHP apps**:** PHP files with any required dependencies
- **Python apps**:** Python files with `requirements.txt` if needed

### 2. Copy Website Files to Config Directory

```bash
# Create directory for your website
mkdir -p ${WEBSITES_CONFIG_PATH}/your-website-name

# Copy your website files
cp -r /path/to/your/website/* ${WEBSITES_CONFIG_PATH}/your-website-name/
```

### 3. Add Service to docker-compose-websites.yml

Open `docker-compose-websites.yml` and add your website service. Here are templates for common website types:

#### Template 1: Static Website (Nginx)

```yaml
your-website-name:
  image: nginx:alpine
  container_name: your-website-name
  hostname: your-website-name
  restart: unless-stopped
  
  networks:
    websites-network:
      ipv4_address: 172.44.0.X  # Use next available IP (start from 172.44.0.2)
  
  ports:
    - "XXXX:80"  # Replace XXXX with your desired port (e.g., 8080, 8081)
  
  environment:
    - PUID=${PUID}
    - PGID=${PGID}
    - TZ=${TZ}
  
  volumes:
    - ${WEBSITES_CONFIG_PATH}/your-website-name:/usr/share/nginx/html:ro
    - /etc/localtime:/etc/localtime:ro
  
  labels:
    - "com.centurylinklabs.watchtower.enable=true"
```

#### Template 2: Node.js Application

```yaml
your-website-name:
  image: node:18-alpine
  container_name: your-website-name
  hostname: your-website-name
  restart: unless-stopped
  
  working_dir: /app
  
  networks:
    websites-network:
      ipv4_address: 172.44.0.X
  
  ports:
    - "XXXX:3000"  # Adjust port based on your app (3000, 8000, etc.)
  
  environment:
    - PUID=${PUID}
    - PGID=${PGID}
    - TZ=${TZ}
    - NODE_ENV=production
    # Add your app-specific environment variables here
  
  volumes:
    - ${WEBSITES_CONFIG_PATH}/your-website-name:/app
    - /etc/localtime:/etc/localtime:ro
  
  command: npm start  # Or: node server.js, npm run start, etc.
  
  labels:
    - "com.centurylinklabs.watchtower.enable=true"
```

#### Template 3: PHP Application (Apache)

```yaml
your-website-name:
  image: php:8.2-apache
  container_name: your-website-name
  hostname: your-website-name
  restart: unless-stopped
  
  networks:
    websites-network:
      ipv4_address: 172.44.0.X
  
  ports:
    - "XXXX:80"
  
  environment:
    - PUID=${PUID}
    - PGID=${PGID}
    - TZ=${TZ}
  
  volumes:
    - ${WEBSITES_CONFIG_PATH}/your-website-name:/var/www/html:ro
    - /etc/localtime:/etc/localtime:ro
  
  labels:
    - "com.centurylinklabs.watchtower.enable=true"
```

#### Template 4: Python Application

```yaml
your-website-name:
  image: python:3.11-alpine
  container_name: your-website-name
  hostname: your-website-name
  restart: unless-stopped
  
  working_dir: /app
  
  networks:
    websites-network:
      ipv4_address: 172.44.0.X
  
  ports:
    - "XXXX:8000"  # Adjust based on your app
  
  environment:
    - PUID=${PUID}
    - PGID=${PGID}
    - TZ=${TZ}
  
  volumes:
    - ${WEBSITES_CONFIG_PATH}/your-website-name:/app
    - /etc/localtime:/etc/localtime:ro
  
  command: python app.py  # Or: uvicorn app:app, gunicorn app:app, etc.
  
  labels:
    - "com.centurylinklabs.watchtower.enable=true"
```

### 4. Configure Environment Variables

If your website needs environment variables, add them to `.env-websites`:

```bash
# Website-specific variables
YOUR_WEBSITE_API_KEY=your_api_key_here
YOUR_WEBSITE_DB_URL=postgresql://user:pass@host:5432/dbname
```

Then reference them in your service:

```yaml
environment:
  - PUID=${PUID}
  - PGID=${PGID}
  - TZ=${TZ}
  - API_KEY=${YOUR_WEBSITE_API_KEY}
  - DB_URL=${YOUR_WEBSITE_DB_URL}
```

### 5. Deploy the Stack

```bash
# Deploy the updated stack
docker-compose --env-file .env-websites -f docker-compose-websites.yml up -d

# Check if your website is running
docker ps | grep your-website-name

# View logs if needed
docker logs your-website-name
```

## IP Address Allocation

Each website service needs a unique IP address in the `172.44.0.0/24` network:

- **172.44.0.2** - First website
- **172.44.0.3** - Second website
- **172.44.0.4** - Third website
- ... and so on
- **172.44.0.254** - Reserved for watchtower

**Important:** Always use the next available IP address. Don't skip numbers.

## Port Selection

Choose ports that don't conflict with other services. Common ports to avoid:

- **8080** - qBittorrent
- **8090** - SABnzbd
- **8989** - Sonarr
- **7878** - Radarr
- **8686** - Lidarr
- **6767** - Bazarr
- **5452** - FileBot
- **32400** - Plex
- **5055** - Overseerr
- **8181** - Tautulli
- **8409** - ErsatzTV
- **4533** - Navidrome
- **5678** - n8n
- **9001** - Mealie
- **7575** - Homarr
- **3001** - Uptime Kuma

**Recommended port ranges for websites:**
- **8000-8099** - Web applications
- **9000-9099** - Custom services
- **10000-10099** - Additional websites

## Volume Mounts

### Read-Only Mounts (Recommended for Static Sites)
```yaml
volumes:
  - ${WEBSITES_CONFIG_PATH}/your-website:/usr/share/nginx/html:ro
```

### Read-Write Mounts (For Apps That Need to Write)
```yaml
volumes:
  - ${WEBSITES_CONFIG_PATH}/your-website:/app
```

### Multiple Volume Mounts
```yaml
volumes:
  - ${WEBSITES_CONFIG_PATH}/your-website:/app
  - ${WEBSITES_CONFIG_PATH}/your-website/uploads:/app/uploads
  - ${DATA_PATH}/shared:/shared:ro
```

## Network Communication

### Accessing Other Stacks

If your website needs to communicate with services in other stacks, you can:

1. **Use host networking** (not recommended for security):
```yaml
network_mode: host
```

2. **Use container names** (if on same Docker network):
```yaml
# Access via container name
http://sonarr:8989
```

3. **Use IP addresses** (for cross-stack communication):
```yaml
# Access via IP
http://172.39.0.5:8989  # Sonarr IP
```

## Examples

### Example 1: React/Next.js Static Site

```yaml
mindkindproject-v2:
  image: nginx:alpine
  container_name: mindkindproject-v2
  hostname: mindkindproject-v2
  restart: unless-stopped
  
  networks:
    websites-network:
      ipv4_address: 172.44.0.2
  
  ports:
    - "8001:80"
  
  environment:
    - PUID=${PUID}
    - PGID=${PGID}
    - TZ=${TZ}
  
  volumes:
    - ${WEBSITES_CONFIG_PATH}/mindkindproject-v2:/usr/share/nginx/html:ro
    - /etc/localtime:/etc/localtime:ro
  
  labels:
    - "com.centurylinklabs.watchtower.enable=true"
```

**Build and deploy:**
```bash
# Build your Next.js app
cd /path/to/mindkindproject-v2
npm run build

# Copy build output
cp -r .next/standalone/* ${WEBSITES_CONFIG_PATH}/mindkindproject-v2/
cp -r .next/static ${WEBSITES_CONFIG_PATH}/mindkindproject-v2/.next/
cp -r public ${WEBSITES_CONFIG_PATH}/mindkindproject-v2/
```

### Example 2: Node.js API Server

```yaml
thegaragelabs-api:
  image: node:18-alpine
  container_name: thegaragelabs-api
  hostname: thegaragelabs-api
  restart: unless-stopped
  
  working_dir: /app
  
  networks:
    websites-network:
      ipv4_address: 172.44.0.3
  
  ports:
    - "8002:3000"
  
  environment:
    - PUID=${PUID}
    - PGID=${PGID}
    - TZ=${TZ}
    - NODE_ENV=production
    - PORT=3000
  
  volumes:
    - ${WEBSITES_CONFIG_PATH}/thegaragelabs-api:/app
    - /etc/localtime:/etc/localtime:ro
  
  command: npm start
  
  labels:
    - "com.centurylinklabs.watchtower.enable=true"
```

## Troubleshooting

### Website Not Accessible

1. **Check container status:**
```bash
docker ps | grep your-website-name
docker logs your-website-name
```

2. **Check port conflicts:**
```bash
netstat -tulpn | grep :XXXX
```

3. **Check network connectivity:**
```bash
docker network inspect websites-network
```

### Permission Issues

If you see permission errors:

```bash
# Fix ownership
sudo chown -R ${PUID}:${PGID} ${WEBSITES_CONFIG_PATH}/your-website-name

# Fix permissions
sudo chmod -R 755 ${WEBSITES_CONFIG_PATH}/your-website-name
```

### Container Keeps Restarting

Check logs for errors:
```bash
docker logs your-website-name --tail 50
```

Common issues:
- Missing environment variables
- Incorrect file paths
- Port already in use
- Missing dependencies

## Best Practices

1. **Use read-only mounts** for static files when possible
2. **Set proper file permissions** before deploying
3. **Use environment variables** for sensitive data (API keys, passwords)
4. **Test locally** before deploying to production
5. **Keep container images updated** (handled by watchtower)
6. **Use specific image tags** instead of `latest` for production
7. **Document your website** in the compose file with comments
8. **Backup your website files** regularly

## Removing a Website

To remove a website:

1. **Stop and remove the container:**
```bash
docker-compose --env-file .env-websites -f docker-compose-websites.yml stop your-website-name
docker-compose --env-file .env-websites -f docker-compose-websites.yml rm your-website-name
```

2. **Remove the service from docker-compose-websites.yml**

3. **Optionally remove website files:**
```bash
rm -rf ${WEBSITES_CONFIG_PATH}/your-website-name
```

## Next Steps

- Add your websites to Homarr dashboard for easy access
- Set up reverse proxy (Nginx Proxy Manager) for custom domains
- Configure SSL certificates for HTTPS
- Set up monitoring in Uptime Kuma
- Create backups of your website configurations

