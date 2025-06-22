# Contributing to Homelab Media Stack

Thank you for considering contributing to the Homelab Media Stack! This project thrives on community contributions, and we welcome help from developers, documentation writers, testers, and users of all skill levels.

## 🤝 How to Contribute

### Types of Contributions We Welcome

- 🐛 **Bug fixes** and improvements
- 📖 **Documentation** enhancements and translations
- ✨ **New features** and service integrations
- 🔧 **Platform-specific guides** (Synology, Unraid, Proxmox, etc.)
- 🛡️ **Security improvements** and best practices
- ⚡ **Performance optimizations**
- 🎨 **User experience** improvements
- 🧪 **Testing** on different platforms and configurations

### What We're Looking For

#### High Priority
- **Additional VPN provider** configurations and examples
- **Platform-specific installation guides** (Synology DSM, Unraid, Proxmox, etc.)
- **Troubleshooting solutions** for edge cases
- **Security enhancements** and hardening guides
- **Performance optimizations** for different hardware configurations

#### Medium Priority
- **Alternative service integrations** (different indexers, download clients)
- **Monitoring and alerting** improvements
- **Backup and restore** automation
- **Multi-language documentation**

#### Nice to Have
- **UI/UX improvements** for configuration
- **Advanced automation** features
- **Integration guides** with other homelab services

## 🚀 Getting Started

### Prerequisites

Before contributing, make sure you have:

- **Docker & Docker Compose** installed
- **Git** for version control
- **VPN account** for testing download functionality
- **Basic understanding** of Docker containers and networking
- **Text editor** or IDE of your choice

### Development Environment Setup

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/your-username/homelab-media-stack.git
   cd homelab-media-stack
   ```

3. **Create a development branch**:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

4. **Set up the stack** for testing:
   ```bash
   # Linux/Mac
   ./scripts/setup.sh
   
   # Windows
   PowerShell -ExecutionPolicy Bypass -File scripts\setup.ps1
   ```

5. **Configure test environment**:
   ```bash
   cp .env-servarr.example .env-servarr
   cp .env-streamarr.example .env-streamarr
   # Edit with your test credentials
   ```

## 📝 Contribution Guidelines

### Code Contributions

#### Docker Compose Files
- **Use specific image tags** instead of `latest` for stability
- **Include health checks** for critical services
- **Follow consistent formatting** (2-space indentation)
- **Add comments** explaining complex configurations
- **Test on multiple platforms** when possible

#### Environment Files
- **Use placeholder values** for sensitive data
- **Include comprehensive comments** explaining each setting
- **Group related settings** logically
- **Provide examples** for common configurations

#### Scripts
- **Include error handling** for all failure scenarios
- **Use consistent logging** with colored output
- **Support both interactive and non-interactive** modes
- **Test on multiple shell environments** (bash, zsh, etc.)
- **Include help text** and usage examples

### Documentation Contributions

#### Writing Standards
- **Use clear, concise language** accessible to beginners
- **Include practical examples** for all instructions
- **Test all commands** before documenting them
- **Use consistent formatting** and markdown syntax
- **Add screenshots** where helpful (but avoid outdated UI images)

#### Documentation Structure
- **Follow existing structure** and navigation
- **Update table of contents** when adding new sections
- **Cross-reference related documentation**
- **Include troubleshooting notes** for common issues

### Commit Guidelines

#### Commit Message Format
```
type(scope): brief description

Longer description if needed, explaining what changed and why.

Fixes #issue-number (if applicable)
```

#### Commit Types
- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code formatting (no functional changes)
- **refactor**: Code restructuring (no functional changes)
- **test**: Adding or updating tests
- **chore**: Maintenance tasks (dependency updates, etc.)

#### Examples
```
feat(vpn): add support for Mullvad VPN provider

- Added Mullvad configuration examples
- Updated documentation with setup instructions
- Tested with WireGuard and OpenVPN protocols

Fixes #123
```

```
docs(troubleshooting): add section for Synology NAS issues

- Common permission problems on DSM 7.0
- Docker network configuration issues
- Package Center vs Docker installation

Closes #456
```

## 🧪 Testing

### Before Submitting

1. **Test your changes** on a clean environment
2. **Verify all services start** and communicate properly
3. **Test the complete workflow** (request → download → process → stream)
4. **Check for breaking changes** in existing functionality
5. **Update documentation** if your changes affect user setup

### Testing Checklist

#### For Code Changes
- [ ] All containers start successfully
- [ ] VPN connectivity works
- [ ] Services can communicate with each other
- [ ] No permission issues with file operations
- [ ] No breaking changes to existing configurations

#### For Documentation Changes
- [ ] All commands work as documented
- [ ] Links are functional and point to correct resources
- [ ] Formatting renders correctly
- [ ] Information is accurate and up-to-date

#### Platform-Specific Testing
- [ ] Test on target platform (if adding platform-specific guide)
- [ ] Verify commands work with platform defaults
- [ ] Document any platform-specific requirements or limitations

## 📋 Pull Request Process

### Before Creating PR

1. **Ensure your branch is up-to-date**:
   ```bash
   git checkout main
   git pull upstream main
   git checkout your-feature-branch
   git rebase main
   ```

2. **Test thoroughly** on a clean environment
3. **Update documentation** if needed
4. **Add entries to CHANGELOG.md** for user-facing changes

### Pull Request Template

When creating your PR, please include:

- **Clear description** of what the PR does
- **Link to related issues** (if applicable)
- **Testing performed** and platforms tested
- **Screenshots** (if UI changes)
- **Breaking changes** (if any)
- **Documentation updates** included

### Review Process

1. **Automated checks** will run (if configured)
2. **Maintainer review** for code quality and standards
3. **Community testing** for complex changes
4. **Documentation review** for accuracy
5. **Final approval** and merge

## 🐛 Bug Reports

### Before Reporting

1. **Check existing issues** to avoid duplicates
2. **Test with latest version** to ensure bug still exists
3. **Gather information** using our support bundle script:
   ```bash
   # Create support bundle (remove sensitive data before sharing!)
   mkdir support-logs-$(date +%Y%m%d)
   docker logs gluetun > support-logs-$(date +%Y%m%d)/gluetun.log
   docker logs sonarr > support-logs-$(date +%Y%m%d)/sonarr.log
   docker ps -a > support-logs-$(date +%Y%m%d)/containers.txt
   ```

### Good Bug Reports Include

- **Clear description** of the problem
- **Steps to reproduce** the issue
- **Expected vs actual behavior**
- **Environment information** (OS, Docker version, etc.)
- **Relevant logs** (with sensitive data removed)
- **Configuration details** (sanitized)

## ✨ Feature Requests

### Before Requesting

1. **Check existing issues** and discussions
2. **Consider if it fits** the project scope
3. **Think about implementation** complexity
4. **Consider alternatives** that might achieve the same goal

### Good Feature Requests Include

- **Clear use case** and problem being solved
- **Proposed solution** (if you have ideas)
- **Alternative solutions** considered
- **Implementation complexity** assessment
- **Breaking changes** potential

## 🛡️ Security

### Reporting Security Issues

**Do not** create public issues for security vulnerabilities. Instead:

1. **Email security concerns** to [your-email] (create security email)
2. **Include detailed description** of the vulnerability
3. **Provide steps to reproduce** if possible
4. **Suggest fixes** if you have ideas

### Security Best Practices

- **Never commit sensitive data** (passwords, tokens, keys)
- **Use environment variables** for all configuration
- **Follow principle of least privilege**
- **Keep dependencies updated**
- **Validate all user inputs**

## 🌍 Community Guidelines

### Code of Conduct

We are committed to providing a welcoming and inclusive environment:

- **Be respectful** and constructive in discussions
- **Help newcomers** learn and contribute
- **Give credit** where credit is due
- **Focus on collaboration** over competition
- **Assume good intentions** in communications

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and community chat
- **Pull Requests**: Code review and technical discussions

## 🏷️ Release Process

### Versioning

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR** version: Incompatible changes
- **MINOR** version: New features (backward compatible)
- **PATCH** version: Bug fixes (backward compatible)

### Release Schedule

- **Patch releases**: As needed for critical bugs
- **Minor releases**: Monthly (when new features are ready)
- **Major releases**: As needed for significant changes

## 🎓 Learning Resources

### Docker & Containerization
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Best Practices for Writing Dockerfiles](https://docs.docker.com/develop/dev-best-practices/)

### Media Server Technologies
- [Servarr Wiki](https://wiki.servarr.com/) - Comprehensive guides for *arr applications
- [Plex Support](https://support.plex.tv/) - Official Plex documentation
- [TRaSH Guides](https://trash-guides.info/) - Quality profiles and best practices

### Networking & VPN
- [Gluetun Documentation](https://github.com/qdm12/gluetun/wiki) - VPN container setup
- [Docker Networking](https://docs.docker.com/network/) - Container networking concepts

## 📞 Getting Help

### For Contributors

- **Check existing documentation** first
- **Search closed issues** for similar problems
- **Ask in GitHub Discussions** for general questions
- **Join community forums** for broader homelab discussions

### Response Times

- **Bug reports**: 2-3 days for initial response
- **Feature requests**: 1 week for initial review
- **Pull requests**: 3-5 days for initial review
- **Security issues**: 24 hours for acknowledgment

## 🙏 Recognition

### Contributors

All contributors are recognized in:

- **GitHub contributors list**
- **CHANGELOG.md** for significant contributions
- **README.md** acknowledgments section

### Maintainers

Current maintainers:
- [@your-username] - Project creator and lead maintainer

---

## 🚀 Ready to Contribute?

1. **Star the repository** if you find it useful
2. **Fork and clone** to get started
3. **Pick an issue** or propose a new feature
4. **Follow the guidelines** above
5. **Submit your contribution**

Thank you for helping make the Homelab Media Stack better for everyone! 🎉

---

*This project is inspired by the amazing homelab and self-hosted communities. Together, we can build something great!*