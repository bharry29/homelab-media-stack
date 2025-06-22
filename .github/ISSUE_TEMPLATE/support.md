---
name: Support Question
about: Get help with setup, configuration, or usage of the Homelab Media Stack
title: '[SUPPORT] '
labels: 'question'
assignees: ''
---

## ❓ Support Question

**What do you need help with?**
A clear description of what you're trying to accomplish or the issue you're facing.

**Is this related to:**
- [ ] Initial setup and installation
- [ ] Configuration and customization
- [ ] Troubleshooting an existing setup
- [ ] Performance optimization
- [ ] Adding new services or features
- [ ] Migration from another setup
- [ ] Best practices and recommendations
- [ ] Other: ___________

## 🎯 What You're Trying to Achieve

**Goal:**
What are you ultimately trying to accomplish?

**Expected outcome:**
What should happen when everything is working correctly?

**Current status:**
Where are you in the process? What's working and what isn't?

## 💻 Your Environment

**System Information:**
- OS: [e.g., Ubuntu 22.04, Windows 11, macOS Ventura, Synology DSM 7.0]
- Hardware: [e.g., Intel NUC, Synology DS920+, Custom build]
- Docker version: [run `docker --version`]
- Installation method: [e.g., Bare metal, VM, NAS, Cloud]

**Network Setup:**
- Local network: [e.g., 192.168.1.0/24]
- Internet connection: [e.g., Gigabit fiber, Cable 500Mbps]
- Router/firewall: [if relevant to your question]

**VPN Information (if applicable):**
- VPN Provider: [e.g., NordVPN, Privado, ExpressVPN]
- VPN Type: [e.g., OpenVPN, WireGuard]
- Server location: [e.g., Netherlands, US East]

## 🔧 Current Configuration

**Installation details:**
- Base path: [e.g., /volume1, /mnt/storage]
- Setup method: [e.g., Automated script, Manual setup]
- When installed: [e.g., Yesterday, Last week, 2 months ago]

**Relevant configuration (sanitize sensitive data):**
```bash
# .env-servarr (relevant parts only)
VPN_SERVICE_PROVIDER=privado
SERVER_COUNTRIES=Netherlands
PUID=1001
PGID=1000

# .env-streamarr (relevant parts only)
PLEX_ADVERTISE_URL=http://192.168.1.100:32400
```

**Modified configurations:**
Have you changed anything from the default setup? If so, what and why?

## 🔍 What You've Tried

**Steps attempted:**
Please list what you've already tried to solve this issue or achieve your goal.

1. Step 1
2. Step 2
3. Step 3

**Documentation consulted:**
- [ ] README.md
- [ ] Quick Start Guide
- [ ] Troubleshooting Guide
- [ ] Searched existing GitHub issues
- [ ] Checked service-specific documentation
- [ ] Other: ___________

**Error messages or unexpected behavior:**
Include any error messages you've encountered or describe what's happening vs. what you expected.

## 📋 Current Service Status

**Container status:**
```bash
# Output of: docker ps
# (paste here if relevant to your question)
```

**Service accessibility (check what applies):**
- [ ] Can access Homarr dashboard (7575)
- [ ] Can access Plex (32400)  
- [ ] Can access Overseerr (5055)
- [ ] Can access qBittorrent (8080)
- [ ] Can access Sonarr (8989)
- [ ] Can access Radarr (7878)
- [ ] VPN connection working
- [ ] Downloads working
- [ ] Media streaming working

## 📜 Relevant Logs (if applicable)

<details>
<summary>Service logs (click to expand)</summary>

```
# If your question relates to a specific service, include recent logs
# docker logs --tail 20 [service-name]
# Remove any sensitive information before pasting
```

</details>

## 🤔 Specific Questions

**Question 1:**
Your first specific question about the setup or configuration.

**Question 2:**
Additional questions you have.

**Best practices:**
Are you looking for recommendations on best practices for your specific use case?

## 🎯 Your Use Case

**Intended usage:**
- [ ] Personal media streaming
- [ ] Family media server
- [ ] Home automation integration
- [ ] Remote access/streaming
- [ ] Multiple user management
- [ ] High-quality 4K content
- [ ] Large media library (10TB+)
- [ ] Low-power/energy efficient setup
- [ ] Other: ___________

**User count:**
How many people will be using this system?

**Content types:**
- [ ] Movies
- [ ] TV Shows
- [ ] Music
- [ ] Audiobooks
- [ ] Documentaries
- [ ] Other: ___________

## 💡 Additional Context

**Constraints or requirements:**
Any specific limitations, requirements, or preferences for your setup?

**Timeline:**
Is this urgent, or are you working on this as a hobby project?

**Experience level:**
- [ ] New to Docker and media servers
- [ ] Some experience with Docker
- [ ] Experienced with Docker and media automation
- [ ] Expert level - looking for advanced configuration

**Related projects:**
Are you migrating from another media server setup? Which one?

## 🎨 Screenshots (if helpful)

**Web interface screenshots:**
If your question relates to web interfaces, screenshots can be very helpful. Make sure to blur out any sensitive information.

**Configuration screens:**
Screenshots of relevant configuration pages.

## 🔄 Next Steps

**What would success look like?**
How will you know when your issue is resolved or your goal is achieved?

**Are you willing to test solutions?**
- [ ] Yes, I can test suggested solutions
- [ ] Yes, but I have limited time
- [ ] I prefer detailed step-by-step instructions
- [ ] I need help understanding the solutions

**Follow-up availability:**
Are you available for follow-up questions if needed to help solve your issue?

## 📚 Learning Interest

**Documentation improvements:**
If we help solve your issue, would better documentation have prevented this question? What could be improved?

**Tutorial interest:**
Would you be interested in a tutorial or guide covering your specific use case?

**Community contribution:**
Once your setup is working, would you be interested in helping others with similar questions?

## 🏷️ Tags for Organization

**Category (select all that apply):**
- [ ] setup-help
- [ ] configuration-help
- [ ] troubleshooting-help
- [ ] performance-help
- [ ] networking-help
- [ ] vpn-help
- [ ] plex-help
- [ ] arr-apps-help
- [ ] filebot-help
- [ ] platform-specific
- [ ] migration-help

**Platform (if relevant):**
- [ ] synology
- [ ] unraid
- [ ] proxmox
- [ ] docker-desktop
- [ ] linux-server
- [ ] windows-server
- [ ] cloud-platform

---

## 📝 For Maintainers

**Triage checklist:**
- [ ] Question is clear and actionable
- [ ] Sufficient information provided
- [ ] Appropriate labels applied
- [ ] Similar issues checked
- [ ] Documentation gap identified

**Response approach:**
- [ ] Direct answer possible
- [ ] Needs troubleshooting steps
- [ ] Requires configuration review
- [ ] Documentation reference sufficient
- [ ] Needs community input

**Follow-up needed:**
- [ ] Request more information
- [ ] Provide step-by-step solution
- [ ] Create/update documentation
- [ ] Escalate to feature request

---

**Thank you for reaching out! The community is here to help. Please provide as much relevant information as possible so we can give you the best assistance.**

*💡 Tip: The more specific your question and the more context you provide, the better help we can offer!*