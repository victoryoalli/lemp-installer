# Contributing to LEMP Installer

First off, thank you for considering contributing to LEMP Installer! It's people like you that make this tool better for everyone.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Style Guidelines](#style-guidelines)
- [Testing](#testing)

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to [your-email@example.com].

### Our Standards

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive criticism
- Show empathy towards others

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples**
- **Describe the behavior you observed and what you expected**
- **Include screenshots if relevant**
- **Include your environment details:**
  - OS version
  - Script version
  - Installation log (if available)

**Template for bug reports:**

```markdown
## Description
A clear description of the bug.

## Steps to Reproduce
1. Run command '...'
2. Select option '...'
3. See error

## Expected Behavior
What you expected to happen.

## Actual Behavior
What actually happened.

## Environment
- OS: Ubuntu 24.04
- Script Version: 1.0.0
- Installation Log: (attach if available)

## Additional Context
Any other context about the problem.
```

### Suggesting Enhancements

Enhancement suggestions are welcome! Please provide:

- **Clear and descriptive title**
- **Detailed description of the proposed feature**
- **Explain why this enhancement would be useful**
- **List any alternative solutions you've considered**

**Template for feature requests:**

```markdown
## Feature Description
A clear description of the feature you'd like to see.

## Problem It Solves
What problem does this feature solve?

## Proposed Solution
How would you implement this?

## Alternatives Considered
What other solutions did you consider?

## Additional Context
Any other context or screenshots.
```

### Your First Code Contribution

Unsure where to begin? Look for issues labeled:

- `good first issue` - Good for newcomers
- `help wanted` - Extra attention needed
- `documentation` - Improvements to docs

### Pull Requests

1. Fork the repo and create your branch from `main`
2. If you've added code, test it thoroughly
3. Update documentation if needed
4. Follow the style guidelines
5. Write a clear commit message

## Development Setup

### Prerequisites

- Ubuntu 22.04 or 24.04 (for testing)
- Virtual machine or cloud instance (for safe testing)
- Basic knowledge of Bash scripting
- Git installed

### Setting Up Your Environment

```bash
# Fork and clone the repository
git clone https://github.com/victoryoalli/lemp-installer.git
cd lemp-installer

# Create a new branch
git checkout -b feature/your-feature-name

# Make your changes
nano install.sh

# Test your changes (in a VM or test server)
sudo ./install.sh
```

### Testing Environment

**IMPORTANT:** Never test installation scripts on production servers!

Recommended testing environments:
- VirtualBox VM
- VMware
- DigitalOcean Droplet (destroy after testing)
- AWS EC2 instance (terminate after testing)
- Multipass (Ubuntu VM manager)

Example using Multipass:

```bash
# Install Multipass
sudo snap install multipass

# Create a test VM
multipass launch 24.04 --name lemp-test --memory 2G --disk 10G

# Transfer script to VM
multipass transfer install.sh lemp-test:/home/ubuntu/

# Access VM
multipass shell lemp-test

# Test the script
sudo ./install.sh

# When done, delete VM
multipass delete lemp-test
multipass purge
```

## Pull Request Process

1. **Update Documentation**
   - Update README.md with any new features
   - Update CHANGELOG.md with your changes
   - Add comments to complex code sections

2. **Test Thoroughly**
   - Test on a fresh Ubuntu 24.04 installation
   - Test on Ubuntu 22.04 if possible
   - Test both successful and error scenarios
   - Test with different configuration options

3. **Commit Message Guidelines**
   ```
   feat: Add support for PostgreSQL
   fix: Correct MySQL password validation
   docs: Update README with new examples
   style: Format code according to guidelines
   refactor: Simplify Nginx configuration
   test: Add test for SSL installation
   chore: Update dependencies
   ```

4. **Submit Pull Request**
   - Fill in the PR template
   - Link to any related issues
   - Request review from maintainers
   - Be responsive to feedback

**Pull Request Template:**

```markdown
## Description
Brief description of changes.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tested on Ubuntu 24.04
- [ ] Tested on Ubuntu 22.04
- [ ] Tested with SSL enabled
- [ ] Tested with SSL disabled
- [ ] Tested with WordPress packages
- [ ] Tested with firewall enabled

## Checklist
- [ ] My code follows the style guidelines
- [ ] I have commented my code where needed
- [ ] I have updated the documentation
- [ ] I have updated CHANGELOG.md
- [ ] My changes generate no new warnings
- [ ] I have tested my changes

## Screenshots (if applicable)
Add screenshots to help explain your changes.

## Additional Notes
Any additional information.
```

## Style Guidelines

### Bash Script Style

1. **Use 4 spaces for indentation** (not tabs)

2. **Add comments for complex logic**
   ```bash
   # Good
   # Check if MySQL is running before creating user
   if systemctl is-active --quiet mysql; then
       # User creation logic here
   fi
   ```

3. **Use meaningful variable names**
   ```bash
   # Good
   MYSQL_USER="web"
   NGINX_CONFIG="/etc/nginx/sites-available/mysite"
   
   # Bad
   u="web"
   nc="/etc/nginx/sites-available/mysite"
   ```

4. **Always quote variables**
   ```bash
   # Good
   echo "User: $SYSTEM_USER"
   cd "$HOME_DIR"
   
   # Bad
   echo "User: $SYSTEM_USER"
   cd $HOME_DIR
   ```

5. **Use functions for reusable code**
   ```bash
   print_error() {
       echo -e "${RED}[ERROR]${NC} $1"
   }
   ```

6. **Check command success**
   ```bash
   # Good
   if nginx -t; then
       systemctl restart nginx
   else
       print_error "Nginx config test failed"
       exit 1
   fi
   ```

7. **Use descriptive function names**
   ```bash
   # Good
   configure_mysql_user()
   setup_nginx_site()
   install_php_extensions()
   
   # Bad
   config()
   setup()
   install()
   ```

### Documentation Style

- Use clear, concise language
- Include code examples
- Add screenshots when helpful
- Keep line length under 80 characters in markdown
- Use proper markdown formatting

### Commit Message Style

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:
```
feat(ssl): Add support for wildcard certificates

Added ability to request wildcard SSL certificates
from Let's Encrypt using DNS validation.

Closes #123
```

```
fix(mysql): Correct password escaping issue

Passwords with special characters were not being
properly escaped when creating MySQL users.

Fixes #456
```

## Testing

### Manual Testing Checklist

Before submitting a PR, test the following scenarios:

#### Basic Installation
- [ ] Fresh Ubuntu 24.04 installation
- [ ] Fresh Ubuntu 22.04 installation
- [ ] With domain name provided
- [ ] Without domain name
- [ ] With custom MySQL username
- [ ] With special characters in password

#### Optional Features
- [ ] WordPress packages enabled
- [ ] WordPress packages disabled
- [ ] SSL installation enabled
- [ ] SSL installation disabled
- [ ] SSH key generation enabled
- [ ] SSH key generation disabled
- [ ] Firewall configuration enabled
- [ ] Firewall configuration disabled

#### Error Scenarios
- [ ] Running without sudo
- [ ] Incorrect password confirmation
- [ ] Invalid domain name for SSL
- [ ] Network interruption during installation

#### Post-Installation
- [ ] Nginx is running
- [ ] MySQL is accessible
- [ ] PHP-FPM is running
- [ ] Test PHP file works
- [ ] Laravel deployment successful
- [ ] SSL redirects working (if enabled)

### Automated Testing

We're working on adding automated tests. Contributions for this are especially welcome!

## Questions?

Don't hesitate to ask questions by:
- Opening an issue
- Joining our discussions
- Contacting the maintainers

## Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- Project documentation

Thank you for contributing! 🎉
