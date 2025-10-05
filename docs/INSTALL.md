# Installation Guide

This guide provides detailed installation instructions for the Inventory Management System on Linux, macOS, and Windows, including setup for local development with .local hostnames.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Linux Installation](#linux-installation)
- [macOS Installation](#macos-installation)
- [Windows Installation](#windows-installation)
- [Local Hostname Setup (.local)](#local-hostname-setup-local)
- [Application Setup](#application-setup)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before installing, ensure you have:
- Administrative/sudo access on your system
- Internet connection for downloading dependencies
- Text editor (VS Code, Sublime Text, or similar)

## Linux Installation

### Ubuntu/Debian

#### 1. Update System Packages
```bash
sudo apt update && sudo apt upgrade -y
```

#### 2. Install Ruby via rbenv (Recommended)
```bash
# Install dependencies
sudo apt install -y git curl libssl-dev libreadline-dev zlib1g-dev \
    autoconf bison build-essential libyaml-dev libreadline-dev \
    libncurses5-dev libffi-dev libgdbm-dev sqlite3 libsqlite3-dev

# Install rbenv
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash

# Add rbenv to PATH
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

# Install Ruby 3.4.1
rbenv install 3.4.1
rbenv global 3.4.1
```

#### 3. Install Node.js (for asset compilation)
```bash
# Using NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

#### 4. Install Git
```bash
sudo apt install -y git
```

### CentOS/RHEL/Fedora

#### 1. Update System
```bash
# CentOS/RHEL
sudo yum update -y
# Fedora
sudo dnf update -y
```

#### 2. Install Dependencies
```bash
# CentOS/RHEL
sudo yum groupinstall -y "Development Tools"
sudo yum install -y git curl openssl-devel readline-devel zlib-devel \
    libyaml-devel libffi-devel sqlite-devel

# Fedora
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y git curl openssl-devel readline-devel zlib-devel \
    libyaml-devel libffi-devel sqlite-devel
```

#### 3. Install Ruby and Node.js
Follow the same rbenv and Node.js installation steps as Ubuntu.

### Arch Linux

#### 1. Update System
```bash
sudo pacman -Syu
```

#### 2. Install Dependencies
```bash
sudo pacman -S base-devel git curl openssl readline zlib libyaml \
    libffi sqlite nodejs npm
```

#### 3. Install Ruby via rbenv
Follow the same rbenv installation steps as Ubuntu.

## macOS Installation

### Using Homebrew (Recommended)

#### 1. Install Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 2. Install Dependencies
```bash
brew install rbenv ruby-build node git sqlite
```

#### 3. Setup rbenv
```bash
# Add rbenv to shell profile
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(rbenv init -)"' >> ~/.zshrc
source ~/.zshrc

# Install Ruby 3.4.1
rbenv install 3.4.1
rbenv global 3.4.1
```

### Using MacPorts (Alternative)

#### 1. Install MacPorts
Download and install from: https://www.macports.org/install.php

#### 2. Install Dependencies
```bash
sudo port install ruby34 +universal
sudo port install nodejs18 +universal
sudo port install git sqlite3
sudo port select --set ruby ruby34
```

## Windows Installation

### Using Windows Subsystem for Linux (WSL) - Recommended

#### 1. Enable WSL
Open PowerShell as Administrator:
```powershell
wsl --install
```
Restart your computer when prompted.

#### 2. Install Ubuntu from Microsoft Store
- Open Microsoft Store
- Search for "Ubuntu 22.04 LTS"
- Install and launch

#### 3. Follow Linux Installation
Once in Ubuntu WSL, follow the Ubuntu/Debian installation steps above.

### Native Windows Installation

#### 1. Install RubyInstaller
- Download Ruby+Devkit 3.4.x from: https://rubyinstaller.org/
- Run installer with default options
- When prompted, install MSYS2 development toolchain

#### 2. Install Node.js
- Download from: https://nodejs.org/
- Install LTS version with default options

#### 3. Install Git
- Download from: https://git-scm.com/download/win
- Install with default options

#### 4. Install SQLite
- Download precompiled binaries from: https://sqlite.org/download.html
- Extract to `C:\sqlite`
- Add `C:\sqlite` to system PATH

#### 5. Setup Development Environment
Open Command Prompt or PowerShell:
```cmd
# Verify installations
ruby --version
node --version
git --version
```

## Local Hostname Setup (.local)

### Linux

#### 1. Install Avahi (mDNS/Bonjour)
```bash
# Ubuntu/Debian
sudo apt install -y avahi-daemon avahi-utils

# CentOS/RHEL
sudo yum install -y avahi avahi-tools
sudo systemctl enable avahi-daemon
sudo systemctl start avahi-daemon

# Fedora
sudo dnf install -y avahi avahi-tools
sudo systemctl enable avahi-daemon
sudo systemctl start avahi-daemon

# Arch Linux
sudo pacman -S avahi nss-mdns
sudo systemctl enable avahi-daemon
sudo systemctl start avahi-daemon
```

#### 2. Configure Hostname
```bash
# Set your desired hostname
sudo hostnamectl set-hostname inventory-dev

# Edit /etc/hosts
sudo nano /etc/hosts
# Add line:
127.0.0.1    inventory-dev.local
```

#### 3. Configure NSS (Name Service Switch)
```bash
sudo nano /etc/nsswitch.conf
# Modify the hosts line to include mdns_minimal:
hosts: files mdns_minimal [NOTFOUND=return] dns
```

### macOS

#### 1. Built-in Bonjour Support
macOS has built-in Bonjour support, so .local hostnames work automatically.

#### 2. Set Computer Name
```bash
# Set computer name (appears as computername.local)
sudo scutil --set ComputerName "Inventory-Dev"
sudo scutil --set LocalHostName "inventory-dev"
sudo scutil --set HostName "inventory-dev.local"

# Restart mDNS
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

#### 3. Add Custom .local Entry
```bash
# Edit /etc/hosts
sudo nano /etc/hosts
# Add line:
127.0.0.1    inventory-dev.local
```

### Windows

#### 1. Install Bonjour Print Services
- Download from Apple: https://support.apple.com/kb/DL999
- Install with default options

#### 2. Edit Hosts File
Open Notepad as Administrator, then open `C:\Windows\System32\drivers\etc\hosts`
Add line:
```
127.0.0.1    inventory-dev.local
```

#### 3. Alternative: Use WSL
If using WSL, the .local hostname will work automatically within the WSL environment.

## Application Setup

### 1. Clone Repository
```bash
git clone <repository-url>
cd frozen-inventory
```

### 2. Install Ruby Dependencies
```bash
# Install bundler
gem install bundler

# Install application gems
bundle install
```

### 3. Install JavaScript Dependencies
```bash
npm install
```

### 4. Database Setup
```bash
# Create database
rails db:create

# Run migrations
rails db:migrate

# Seed with sample data (optional)
rails db:seed
```

### 5. Configure Application
```bash
# Copy environment template (if exists)
cp .env.example .env

# Generate Rails credentials (if needed)
EDITOR=nano rails credentials:edit
```

### 6. Start Development Server
```bash
# Option 1: Standard Rails server
rails server

# Option 2: Bind to custom hostname
rails server -b inventory-dev.local -p 3000

# Option 3: Bind to all interfaces
rails server -b 0.0.0.0 -p 3000
```

## Verification

### 1. Test Ruby Installation
```bash
ruby --version
# Should show: ruby 3.4.x

gem --version
# Should show gem version

bundle --version
# Should show bundler version
```

### 2. Test Node.js Installation
```bash
node --version
# Should show: v20.x.x or later

npm --version
# Should show npm version
```

### 3. Test Database Connection
```bash
rails console
# In Rails console:
ActiveRecord::Base.connection.execute("SELECT 1")
# Should return successful result
```

### 4. Test .local Hostname
```bash
# Test resolution
ping inventory-dev.local
nslookup inventory-dev.local

# Test web access
curl http://inventory-dev.local:3000
# Or open in browser: http://inventory-dev.local:3000
```

### 5. Test Application Features
1. Open browser to `http://inventory-dev.local:3000` (or `http://localhost:3000`)
2. Create a new location
3. Create a new item
4. Add item to location
5. Test barcode generation and scanning
6. Verify multilingual support by changing language

## Troubleshooting

### Common Ruby Issues

#### rbenv: command not found
```bash
# Add to shell profile
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc
```

#### Bundle install fails
```bash
# Update bundler
gem update bundler

# Clear bundle cache
bundle clean --force

# Reinstall
bundle install
```

#### Permission errors on macOS
```bash
# Fix permissions
sudo chown -R $(whoami) ~/.rbenv
```

### Common Database Issues

#### SQLite3 gem installation fails
```bash
# Linux: Install development headers
sudo apt install libsqlite3-dev  # Ubuntu/Debian
sudo yum install sqlite-devel    # CentOS/RHEL

# macOS: Install via Homebrew
brew install sqlite

# Windows: Ensure SQLite is in PATH
```

#### Database locked error
```bash
# Stop all Rails servers
pkill -f rails

# Remove lock files
rm -f tmp/pids/server.pid

# Restart server
rails server
```

### .local Hostname Issues

#### .local not resolving on Linux
```bash
# Check Avahi status
sudo systemctl status avahi-daemon

# Restart Avahi
sudo systemctl restart avahi-daemon

# Check NSS configuration
cat /etc/nsswitch.conf | grep hosts
```

#### .local not resolving on Windows
- Ensure Bonjour Print Services is installed
- Check Windows Firewall settings
- Try using IP address (127.0.0.1:3000) instead

#### .local not resolving on macOS
```bash
# Flush DNS cache
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# Check mDNS service
sudo launchctl list | grep mdns
```

### Performance Issues

#### Slow asset compilation
```bash
# Precompile assets for development
rails assets:precompile

# Use faster JavaScript runtime
# Add to Gemfile: gem 'mini_racer'
bundle install
```

#### Slow database queries
```bash
# Enable query logging
# In config/environments/development.rb:
config.log_level = :debug
```

### Port Already in Use
```bash
# Find process using port 3000
sudo lsof -i :3000  # Linux/macOS
netstat -ano | findstr :3000  # Windows

# Kill process
kill -9 <PID>  # Linux/macOS
taskkill /PID <PID> /F  # Windows

# Or use different port
rails server -p 3001
```

## Additional Resources

- [Ruby Installation Guide](https://www.ruby-lang.org/en/documentation/installation/)
- [Rails Getting Started](https://guides.rubyonrails.org/getting_started.html)
- [rbenv Documentation](https://github.com/rbenv/rbenv)
- [Homebrew Documentation](https://docs.brew.sh/)
- [WSL Documentation](https://docs.microsoft.com/en-us/windows/wsl/)

## Support

If you encounter issues not covered in this guide:

1. Check application logs in `log/development.log`
2. Review system logs for Avahi/mDNS issues
3. Verify all prerequisites are correctly installed
4. Test with default Rails settings before customizing
5. Create an issue in the project repository with:
   - Operating system and version
   - Ruby version (`ruby --version`)
   - Rails version (`rails --version`)
   - Error messages and stack traces
   - Steps to reproduce the issue

---

**Last Updated**: October 2025
**Supported Platforms**: Linux (Ubuntu 20.04+, CentOS 8+, Arch), macOS 12+, Windows 10/11