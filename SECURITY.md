# Security Policy

## Supported Versions

We actively support the following versions of ASUSWRT-Merlin NginxUI with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

### How to Report

We take security vulnerabilities seriously. If you discover a security vulnerability, please report it responsibly:

1. **DO NOT** create a public GitHub issue for security vulnerabilities
2. **DO NOT** disclose the vulnerability publicly until it has been addressed
3. **DO** report it privately using one of the methods below:

#### Preferred Method: GitHub Security Advisories

1. Go to the [Security tab](https://github.com/your-org/asuswrt-merlin-nginxui/security) of this repository
2. Click "Report a vulnerability"
3. Fill out the vulnerability report form

#### Alternative Method: Email

Send an email to: `security@your-domain.com`

**Include the following information:**
- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact
- Suggested fix (if any)
- Your contact information

### What to Expect

1. **Acknowledgment**: We will acknowledge receipt within 48 hours
2. **Initial Assessment**: We will provide an initial assessment within 5 business days
3. **Investigation**: We will investigate and work on a fix
4. **Resolution**: We will notify you when the vulnerability is resolved
5. **Disclosure**: We will coordinate public disclosure with you

### Response Timeline

- **Critical vulnerabilities**: 24-48 hours for initial response
- **High severity**: 3-5 business days for initial response
- **Medium/Low severity**: 5-10 business days for initial response

## Security Considerations

### Router Security

This application runs on ASUSWRT-Merlin routers, which are network edge devices. Special security considerations include:

#### Network Exposure
- The web interface should only be accessible from trusted networks
- Consider using VPN access for remote management
- Regularly update router firmware

#### Authentication
- Use strong passwords for router admin accounts
- Enable two-factor authentication if available
- Regularly rotate credentials

#### Access Control
- Limit administrative access to necessary users only
- Use principle of least privilege
- Monitor access logs regularly

### Application Security

#### Input Validation
- All user inputs are validated and sanitized
- Configuration parameters are checked against allowed values
- File uploads are restricted and validated

#### Command Execution
- Shell commands are properly escaped and validated
- No user input is directly executed without sanitization
- Commands run with minimal required privileges

#### Data Protection
- Sensitive configuration data is protected
- Logs may contain sensitive information - handle appropriately
- Backup files should be secured

### Secure Configuration

#### Recommended Settings

1. **Network Access**
   ```bash
   # Limit access to management interface
   iptables -A INPUT -p tcp --dport 80 -s 192.168.1.0/24 -j ACCEPT
   iptables -A INPUT -p tcp --dport 80 -j DROP
   ```

2. **SSL/TLS Configuration**
   - Use strong cipher suites
   - Disable weak protocols (SSLv2, SSLv3)
   - Implement proper certificate validation

3. **File Permissions**
   ```bash
   # Secure script permissions
   chmod 750 /opt/nginxui/backend/*.sh
   chown root:admin /opt/nginxui/backend/*.sh
   ```

#### Security Headers

The application implements security headers:
- `X-Frame-Options: SAMEORIGIN`
- `X-XSS-Protection: 1; mode=block`
- `X-Content-Type-Options: nosniff`
- `Content-Security-Policy`
- `Referrer-Policy`

### Known Security Considerations

#### Router Environment
- Limited sandboxing capabilities
- Shared system resources
- Network device constraints

#### Web Interface
- Client-side JavaScript execution
- Browser security dependencies
- Cross-site scripting prevention

#### Backend Scripts
- Shell script execution environment
- File system access requirements
- System command execution

### Security Best Practices

#### For Users

1. **Keep Updated**
   - Regularly update ASUSWRT-Merlin firmware
   - Update NginxUI to latest version
   - Monitor security advisories

2. **Network Security**
   - Use strong WiFi passwords
   - Disable WPS if not needed
   - Enable firewall protection
   - Regularly review connected devices

3. **Access Management**
   - Use strong admin passwords
   - Limit administrative access
   - Monitor access logs
   - Use VPN for remote access

#### For Developers

1. **Code Security**
   - Follow secure coding practices
   - Validate all inputs
   - Use parameterized queries
   - Implement proper error handling

2. **Dependencies**
   - Regularly update dependencies
   - Monitor for security advisories
   - Use dependency scanning tools
   - Remove unused dependencies

3. **Testing**
   - Include security testing
   - Test input validation
   - Verify access controls
   - Test error conditions

### Vulnerability Disclosure Policy

#### Coordinated Disclosure

We follow responsible disclosure practices:

1. **Private Reporting**: Vulnerabilities reported privately first
2. **Investigation**: We investigate and develop fixes
3. **Coordination**: We coordinate with reporters on disclosure timing
4. **Public Disclosure**: Vulnerabilities disclosed after fixes are available

#### Recognition

We recognize security researchers who report vulnerabilities responsibly:
- Credit in security advisories (with permission)
- Recognition in release notes
- Hall of fame listing (if desired)

### Security Resources

#### Documentation
- [ASUSWRT-Merlin Security Guide](https://github.com/RMerl/asuswrt-merlin.ng/wiki/Security)
- [Nginx Security Best Practices](https://nginx.org/en/docs/http/securing_nginx.html)
- [OWASP Web Application Security](https://owasp.org/www-project-top-ten/)

#### Tools
- [Router Security Checklist](https://routersecurity.org/)
- [Network Security Scanner](https://nmap.org/)
- [Web Application Scanner](https://owasp.org/www-project-zap/)

### Contact Information

- **Security Email**: security@your-domain.com
- **GitHub Security**: Use GitHub Security Advisories
- **General Contact**: See README.md for general contact information

---

**Note**: This security policy is subject to updates. Please check regularly for the latest version.