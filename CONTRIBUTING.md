# Contributing to NginxUI for ASUSWRT-Merlin

🎉 Thank you for your interest in contributing to NginxUI! This project has been enhanced with XrayUI's best practices to provide a robust and reliable web interface for Nginx management on ASUSWRT-Merlin routers.

**✨ Enhanced with XrayUI Architecture** - We've adopted proven patterns for installation reliability, error handling, and system integration.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Enhanced Development Setup](#enhanced-development-setup)
- [Development Workflow](#development-workflow)
- [Code Quality Standards](#code-quality-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation Standards](#documentation-standards)
- [Submitting Changes](#submitting-changes)
- [Release Process](#release-process)
- [Getting Help](#getting-help)

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## 🚀 Getting Started

### Enhanced Prerequisites

- **Node.js 18+** (LTS recommended) and **npm 9+**
- **Git 2.30+** with proper configuration
- **Modern Code Editor** (VS Code recommended)
- **ASUSWRT-Merlin Router** for testing (highly recommended)
- **Knowledge Areas**:
  - Vue 3 Composition API and TypeScript
  - Modern shell scripting with error handling
  - ASUSWRT-Merlin firmware architecture
  - Nginx configuration and management

### Recommended VS Code Extensions

```json
{
  "recommendations": [
    "vue.volar",
    "bradlc.vscode-tailwindcss",
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint",
    "ms-vscode.vscode-typescript-next",
    "timonwong.shellcheck",
    "foxundermoon.shell-format"
  ]
}
```

## 🛠️ Enhanced Development Setup

### 1. Fork and Clone with Submodules

```bash
# Fork the repository on GitHub, then clone your fork
git clone --recursive https://github.com/YOUR_USERNAME/asuswrt-merlin-nginxui.git
cd asuswrt-merlin-nginxui

# Add the original repository as upstream
git remote add upstream https://github.com/NasPilot/asuswrt-merlin-nginxui.git
```

### 2. Enhanced Environment Setup

```bash
# Install dependencies with exact versions
npm ci

# Setup development environment with enhanced tooling
npm run dev:setup

# Install pre-commit hooks for code quality
npm run prepare

# Verify installation
npm run verify-setup
```

### 3. Development Server Options

```bash
# Standard development server with hot reload
npm run dev

# Development server with router proxy (for testing)
npm run dev:router

# Component development with Storybook
npm run dev:storybook

# Development with debug logging
npm run dev:debug
```

### 4. Verify Setup

```bash
# Run comprehensive setup verification
npm run test
npm run lint
npm run type-check
npm run build
```

5. **Run Tests**
   ```bash
   npm test
   ```

## Contributing Guidelines

### Types of Contributions

- **Bug Reports**: Report issues with detailed reproduction steps
- **Feature Requests**: Suggest new features with clear use cases
- **Code Contributions**: Submit bug fixes or new features
- **Documentation**: Improve or add documentation
- **Testing**: Add or improve test coverage

### Before Contributing

1. **Check Existing Issues**: Look for existing issues or discussions
2. **Create an Issue**: For significant changes, create an issue first
3. **Discuss**: Engage with maintainers and community

## Pull Request Process

### 1. Preparation

- Create a feature branch from `main`
- Use descriptive branch names (e.g., `feature/ssl-management`, `fix/config-validation`)

### 2. Development

- Follow coding standards
- Write tests for new functionality
- Update documentation as needed
- Ensure all tests pass

### 3. Commit Guidelines

Use conventional commit format:

```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test additions or modifications
- `chore`: Build process or auxiliary tool changes

**Examples:**
```
feat(ui): add SSL certificate management interface
fix(backend): resolve nginx config validation issue
docs(readme): update installation instructions
```

### 4. Pre-submission Checklist

- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Tests added/updated and passing
- [ ] Documentation updated
- [ ] No merge conflicts
- [ ] Commit messages follow convention

### 5. Submission

1. Push your branch to your fork
2. Create a pull request with:
   - Clear title and description
   - Reference to related issues
   - Screenshots for UI changes
   - Testing instructions

## Coding Standards

### Frontend (Vue.js/TypeScript)

- **Style Guide**: Follow Vue.js style guide
- **TypeScript**: Use strict type checking
- **Components**: Use Composition API
- **Naming**: Use PascalCase for components, camelCase for variables
- **Props**: Define with proper TypeScript interfaces

### Backend (Shell Scripts)

- **Style**: Follow Google Shell Style Guide
- **Functions**: Use descriptive names with proper documentation
- **Error Handling**: Implement comprehensive error checking
- **Variables**: Use meaningful names and proper quoting

### CSS/SCSS

- **Methodology**: Follow BEM naming convention
- **Organization**: Use logical grouping and nesting
- **Variables**: Use CSS custom properties for theming
- **Responsive**: Mobile-first approach

## Testing

### Frontend Testing

- **Unit Tests**: Jest + Vue Test Utils
- **Component Tests**: Test component behavior and props
- **Integration Tests**: Test component interactions

### Backend Testing

- **Shell Script Tests**: Use bats or similar framework
- **Integration Tests**: Test script interactions
- **Manual Testing**: Test on actual ASUSWRT-Merlin router

### Test Guidelines

- Write tests for new features
- Maintain test coverage above 80%
- Test edge cases and error conditions
- Use descriptive test names

## Documentation

### Types of Documentation

- **Code Comments**: Explain complex logic
- **API Documentation**: Document all public interfaces
- **User Documentation**: Update README and guides
- **Developer Documentation**: Architecture and setup guides

### Documentation Standards

- Use clear, concise language
- Include code examples
- Keep documentation up-to-date
- Use proper markdown formatting

## Development Workflow

### Local Development

1. **Start Development Server**
   ```bash
   npm run dev
   ```

2. **Run Linting**
   ```bash
   npm run lint
   npm run lint:style
   ```

3. **Run Tests**
   ```bash
   npm test
   npm run test:coverage
   ```

4. **Type Checking**
   ```bash
   npm run type-check
   ```

### Docker Development

```bash
# Development environment
docker-compose --profile dev up

# Production build
docker-compose up
```

## Release Process

1. **Version Bump**: Update version in package.json
2. **Changelog**: Update CHANGELOG.md
3. **Testing**: Comprehensive testing on target platform
4. **Documentation**: Update documentation
5. **Release**: Create GitHub release with artifacts

## Getting Help

- **Issues**: Create GitHub issues for bugs or questions
- **Discussions**: Use GitHub Discussions for general questions
- **Documentation**: Check existing documentation first

## Recognition

Contributors will be recognized in:
- CHANGELOG.md for significant contributions
- README.md contributors section
- GitHub contributors graph

Thank you for contributing to ASUSWRT-Merlin NginxUI!