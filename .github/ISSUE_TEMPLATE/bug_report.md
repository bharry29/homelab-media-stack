---
name: Bug Report
about: Create a report to help us improve the Homelab Media Stack
title: '[BUG] '
labels: 'bug'
assignees: ''
---

## 🐛 Bug Description

**Brief summary of the issue:**
A clear and concise description of what the bug is.

**Expected behavior:**
What you expected to happen.

**Actual behavior:**
What actually happened instead.

## 🔄 Steps to Reproduce

1. Go to '...'
2. Click on '....'
3. Configure '....'
4. See error

**Minimal reproduction case:**
If possible, provide the smallest configuration that reproduces the issue.

## 💻 Environment Information

**System Details:**
- OS: [e.g., Ubuntu 22.04, Windows 11, macOS Ventura]
- Architecture: [e.g., x86_64, arm64]
- Docker version: [e.g., 24.0.7] (run `docker --version`)
- Docker Compose version: [e.g., 2.21.0] (run `docker-compose --version` or `docker compose version`)

**Hardware:**
- CPU: [e.g., Intel i7-12700K, AMD Ryzen 5 5600X, Apple M2]
- RAM: [e.g., 32GB]
- Storage: [e.g., 1TB NVMe SSD + 8TB HDD]
- Network: [e.g., Gigabit Ethernet, Wi-Fi 6]

**Homelab Setup:**
- Installation method: [e.g., Bare metal, VM, NAS (Synology/QNAP), Proxmox]
- VPN Provider: [e.g., NordVPN, Privado, ExpressVPN]
- Base path: [e.g., /volume1, /mnt/storage, C:\homelab-data]

## ⚙️ Configuration

**Environment files (remove sensitive data):**
```bash
# .env-servarr (sanitized)
VPN_SERVICE_PROVIDER=privado
SERVER_COUNTRIES=Netherlands
# ... other relevant settings

# .env-streamarr (sanitized)  
PLEX_ADVERTISE_URL=http://192.168.1.100:32400
# ... other relevant settings
```

**Relevant docker-compose sections:**
If you've modified any docker-compose files, include the relevant sections.

## 📋 Service Status

**Container status:**
```bash
# Output of: docker ps -a
CONTAINER ID   IMAGE                    STATUS
abc123def456   ghcr.io/hotio/plex      Up 2 hours (healthy)
# ... paste your output here
```

**Service accessibility:**
- [ ] Can access Homarr dashboard (7575)
- [ ] Can access Plex (32400)
- [ ] Can access Overseerr (5055)
- [ ] Can access qBittorrent (8080)
- [ ] VPN is connected (check with: `docker exec qbittorrent curl -s ifconfig.me`)

## 📜 Logs

**Relevant container logs (last 50 lines):**

<details>
<summary>Gluetun (VPN) logs</summary>

```
# Output of: docker logs --tail 50 gluetun
[paste logs here, remove any sensitive information]
```

</details>

<details>
<summary>Affected service logs</summary>

```
# Output of: docker logs --tail 50 [service-name]
[paste logs here, remove any sensitive information]
```

</details>

<details>
<summary>Additional service logs (if relevant)</summary>

```
# Output of: docker logs --tail 50 [other-service]
[paste logs here, remove any sensitive information]
```

</details>

## 🔍 Additional Context

**When did this issue start?**
- [ ] Fresh installation
- [ ] After updating containers
- [ ] After changing configuration
- [ ] After system reboot/restart
- [ ] Other: ___________

**How frequently does this occur?**
- [ ] Always/Every time
- [ ] Sometimes/Intermittently  
- [ ] Rarely
- [ ] Only once

**Error messages:**
Include any error messages you see in web interfaces or logs.

**Screenshots:**
If applicable, add screenshots to help explain your problem. Make sure to blur out any sensitive information.

**Workarounds:**
Have you found any temporary workarounds for this issue?

**Related issues:**
Are there any related issues or similar problems you've found?

## ✅ Troubleshooting Steps Attempted

Please check off the troubleshooting steps you've already tried:

**Basic Steps:**
- [ ] Restarted affected containers (`docker restart [container-name]`)
- [ ] Checked container logs for errors
- [ ] Verified all containers are running (`docker ps`)
- [ ] Checked disk space (`df -h`)

**Network & Connectivity:**
- [ ] Tested VPN connectivity (`docker exec qbittorrent curl -s ifconfig.me`)
- [ ] Verified local service access (http://localhost:port)
- [ ] Checked firewall settings
- [ ] Tested with different network (if applicable)

**Configuration:**
- [ ] Reviewed environment file settings
- [ ] Compared with working example configurations
- [ ] Checked file permissions and ownership
- [ ] Verified PUID/PGID settings match system user

**Documentation:**
- [ ] Consulted the [Troubleshooting Guide](../docs/TROUBLESHOOTING.md)
- [ ] Followed the [Quick Start Guide](../docs/QUICK_START.md)
- [ ] Searched existing GitHub issues

## 🔧 Proposed Solution

If you have any ideas about what might be causing this issue or how to fix it, please share them here.

## 📚 Additional Information

**Is this a regression?**
Did this work in a previous version? If so, which version?

**Impact severity:**
- [ ] Critical - Stack completely unusable
- [ ] High - Major functionality broken
- [ ] Medium - Some features affected
- [ ] Low - Minor inconvenience

**Affected services:**
Which services/features are impacted by this bug?

---

**Note for maintainers:** Please add appropriate labels and assign to relevant milestone after reviewing.