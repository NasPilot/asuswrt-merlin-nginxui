# GitHub Actions Workflows

This directory contains automated workflows for the ASUSWRT-Merlin NginxUI project. These workflows handle continuous integration, deployment, security scanning, and maintenance tasks.

## Workflows Overview

### 🚀 Core Workflows

#### `build-n-release.yml` - Build and Release
- **Triggers**: Git tags (`v*`), manual dispatch
- **Purpose**: Builds the project and creates GitHub releases
- **Features**:
  - Automated version extraction from tags
  - Manual release creation with custom version
  - Draft and prerelease options
  - Artifact upload to releases

#### `ci.yml` - Continuous Integration
- **Triggers**: Push to main/develop, pull requests
- **Purpose**: Runs tests and quality checks on every change
- **Features**:
  - Multi-Node.js version testing (18, 20)
  - Type checking, linting, and testing
  - Build verification
  - Tar.gz package testing

### 🔒 Security & Quality

#### `codeql.yml` - Security Scanning
- **Triggers**: Push, pull requests, weekly schedule
- **Purpose**: Automated security vulnerability scanning
- **Features**:
  - CodeQL security analysis
  - Code coverage reporting
  - Codecov integration

#### `dependency-update.yml` - Dependency Management
- **Triggers**: Weekly schedule (Mondays), manual dispatch
- **Purpose**: Automated dependency updates
- **Features**:
  - Minor/patch version updates
  - Automated testing of updates
  - Pull request creation
  - Automatic reviewer assignment

### 🐳 Container & Deployment

#### `docker.yml` - Docker Image Management
- **Triggers**: Push to main, tags, pull requests
- **Purpose**: Builds and publishes Docker images
- **Features**:
  - Multi-platform builds (amd64, arm64)
  - GitHub Container Registry publishing
  - Security scanning with Trivy
  - Development image testing

#### `docs.yml` - Documentation
- **Triggers**: Documentation file changes, manual dispatch
- **Purpose**: Automated documentation generation and deployment
- **Features**:
  - Markdown linting
  - Link checking
  - API documentation generation
  - VitePress documentation site
  - GitHub Pages deployment

### 📊 Monitoring & Analysis

#### `performance.yml` - Performance Monitoring
- **Triggers**: Push, pull requests, manual dispatch
- **Purpose**: Monitors build performance and bundle size
- **Features**:
  - Bundle size analysis
  - Build time monitoring
  - Lighthouse CI performance testing
  - Dependency analysis
  - Security audit reporting

#### `release-notes.yml` - Release Notes Generation
- **Triggers**: Release published, manual dispatch
- **Purpose**: Automated release notes generation
- **Features**:
  - Changelog generation from commits
  - Contributor listing
  - Release comparison links

## Configuration Files

### `.github/markdown-link-check.json`
Configuration for markdown link checking:
- Ignores local and private network URLs
- Custom headers for GitHub API
- Retry configuration for reliability

## Usage Examples

### Manual Release
1. Go to Actions → Build and Release
2. Click "Run workflow"
3. Enter version (e.g., `v1.2.0`)
4. Choose draft/prerelease options
5. Run workflow

### Dependency Updates
- Runs automatically every Monday
- Creates PR with updated dependencies
- Includes test results and security audit

### Performance Monitoring
- Automatically runs on every PR
- Comments bundle size analysis
- Alerts on performance regressions

## Secrets Required

The following secrets should be configured in repository settings:

- `GITHUB_TOKEN` - Automatically provided by GitHub
- `CODECOV_TOKEN` - For code coverage reporting (optional)

## Permissions

Workflows require the following permissions:
- `contents: read/write` - For repository access
- `packages: write` - For Docker image publishing
- `security-events: write` - For security scanning
- `actions: read` - For workflow access

## Monitoring

### Build Status
All workflows provide status badges that can be added to README:

```markdown
![CI](https://github.com/NasPilot/asuswrt-merlin-nginxui/workflows/Continuous%20Integration/badge.svg)
![Security](https://github.com/NasPilot/asuswrt-merlin-nginxui/workflows/CodeQL%20Security%20Scan/badge.svg)
![Docker](https://github.com/NasPilot/asuswrt-merlin-nginxui/workflows/Build%20and%20Push%20Docker%20Image/badge.svg)
```

### Notifications
- Failed workflows notify repository maintainers
- Security vulnerabilities create issues automatically
- Performance regressions comment on PRs

## Maintenance

### Regular Tasks
1. Review dependency update PRs weekly
2. Monitor security scan results
3. Update workflow versions quarterly
4. Review performance metrics monthly

### Troubleshooting
- Check workflow logs for detailed error information
- Verify required secrets are configured
- Ensure branch protection rules don't conflict
- Review permissions for workflow failures

## Contributing

When modifying workflows:
1. Test changes in a fork first
2. Update this documentation
3. Follow security best practices
4. Use semantic versioning for workflow updates