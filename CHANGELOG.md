# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project structure
- Vue 3 + TypeScript frontend
- Nginx service management
- Basic and advanced configuration modes
- SSL/TLS configuration support
- Upstream and load balancing configuration
- Real-time service status monitoring
- Log viewer with search and filtering
- Multi-language support (English/Chinese)
- Configuration backup and restore
- Integration with ASUSWRT-Merlin router UI

### Changed
- N/A

### Deprecated
- N/A

### Removed
- N/A

### Fixed
- N/A

### Security
- N/A

## [1.0.0] - 2024-01-XX

### Added
- Initial release of ASUSWRT-Merlin NginxUI
- Complete Nginx management interface
- Service control (start, stop, restart, reload)
- Configuration management with validation
- SSL certificate management
- Log management and rotation
- Backup and restore functionality
- Multi-language interface
- Responsive design for router web UI
- Comprehensive installation and setup scripts
- Documentation and user guides

### Features
- **Service Management**: Full control over Nginx service lifecycle
- **Configuration Modes**: Basic mode for beginners, advanced mode for experts
- **SSL Support**: Complete HTTPS configuration and certificate management
- **Load Balancing**: Upstream server configuration with health checks
- **Monitoring**: Real-time status monitoring and statistics
- **Logging**: Access logs, error logs, and system logs with search capabilities
- **Backup**: Automatic configuration backup and manual restore
- **Integration**: Seamless integration with ASUSWRT-Merlin firmware
- **Localization**: Support for English and Chinese languages
- **Security**: Best practices for secure Nginx configuration

### Technical Details
- Built with Vue 3 and TypeScript
- Vite build system for fast development and optimized production builds
- SCSS styling with ASUS router UI integration
- Shell script backend for system integration
- Modular component architecture
- Comprehensive error handling and validation
- Automated testing and CI/CD pipeline

### Installation
- One-click installation script
- Automatic dependency checking and installation
- Integration with router web interface
- Support for multiple router models

### Documentation
- Complete installation guide
- User manual with screenshots
- API documentation
- Troubleshooting guide
- Development setup instructions

---

## Release Notes Format

### Version Numbering
- **Major.Minor.Patch** (e.g., 1.0.0)
- Major: Breaking changes or significant new features
- Minor: New features, backward compatible
- Patch: Bug fixes, backward compatible

### Change Categories
- **Added**: New features
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements

### Links
- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)
- [Project Repository](https://github.com/NasPilot/asuswrt-merlin-nginxui)