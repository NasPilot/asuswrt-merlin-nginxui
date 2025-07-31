# Contributing to ASUSWRT-Merlin NginxUI

Thank you for your interest in contributing to ASUSWRT-Merlin NginxUI! This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Contributing Guidelines](#contributing-guidelines)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## Getting Started

### Prerequisites

- Node.js 18+ and npm
- Git
- Basic knowledge of Vue.js, TypeScript, and shell scripting
- ASUSWRT-Merlin router for testing (recommended)

### Development Setup

1. **Fork and Clone**
   ```bash
   git clone https://github.com/your-username/asuswrt-merlin-nginxui.git
   cd asuswrt-merlin-nginxui
   ```

2. **Install Dependencies**
   ```bash
   npm install
   ```

3. **Setup Environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Start Development Server**
   ```bash
   npm run dev
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