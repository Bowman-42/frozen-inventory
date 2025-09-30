# Deployment Guide

This guide covers various deployment options for the Frozen Inventory Management System.

## Table of Contents

- [Development Setup](#development-setup)
- [Production Deployment](#production-deployment)
- [Docker Deployment](#docker-deployment)
- [Kamal Deployment](#kamal-deployment)
- [Environment Configuration](#environment-configuration)
- [Database Management](#database-management)
- [Monitoring and Maintenance](#monitoring-and-maintenance)

## Development Setup

### Prerequisites

- Ruby 3.4+
- Rails 8.0+
- SQLite3
- Git

### Local Development

1. **Clone and setup**
   ```bash
   git clone <repository-url>
   cd frozen-inventory
   bundle install
   ```

2. **Database setup**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed  # Optional: creates sample data
   ```

3. **Start development server**
   ```bash
   rails server
   # Access at http://localhost:3000
   ```

4. **Run tests**
   ```bash
   rails test
   bundle exec rubocop  # Code style checks
   ```

## Production Deployment

### Server Requirements

**Minimum Requirements:**
- CPU: 1 vCPU
- RAM: 512MB
- Storage: 10GB SSD
- Network: 100 Mbps

**Recommended Requirements:**
- CPU: 2 vCPUs
- RAM: 2GB
- Storage: 20GB SSD
- Network: 1 Gbps

### Traditional Server Deployment

#### 1. Server Preparation

```bash
# Update system (Ubuntu/Debian)
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y ruby-full build-essential zlib1g-dev nodejs yarn sqlite3

# Install bundler
gem install bundler
```

#### 2. Application Deployment

```bash
# Create deployment directory
sudo mkdir -p /var/www/frozen-inventory
sudo chown $USER:$USER /var/www/frozen-inventory

# Deploy application
cd /var/www/frozen-inventory
git clone <repository-url> .
bundle config set --local deployment true
bundle install --without development test
```

#### 3. Environment Configuration

```bash
# Create production environment file
cp .env.example .env.production

# Edit environment variables
nano .env.production
```

```bash
# .env.production
RAILS_ENV=production
SECRET_KEY_BASE=<generate with: rails secret>
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
```

#### 4. Database Setup

```bash
# Production database setup
RAILS_ENV=production rails db:create
RAILS_ENV=production rails db:migrate
```

#### 5. Asset Compilation

```bash
RAILS_ENV=production rails assets:precompile
```

#### 6. Process Management with Systemd

Create service file:

```bash
sudo nano /etc/systemd/system/frozen-inventory.service
```

```ini
[Unit]
Description=Frozen Inventory Rails Application
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/frozen-inventory
Environment=RAILS_ENV=production
Environment=SECRET_KEY_BASE=<your-secret-key>
ExecStart=/usr/local/bin/bundle exec rails server -p 3000 -e production
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

Enable and start service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable frozen-inventory
sudo systemctl start frozen-inventory
sudo systemctl status frozen-inventory
```

#### 7. Web Server (Nginx)

```bash
sudo apt install nginx

sudo nano /etc/nginx/sites-available/frozen-inventory
```

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable site:

```bash
sudo ln -s /etc/nginx/sites-available/frozen-inventory /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## Docker Deployment

### Using the Provided Dockerfile

The application includes a production-ready Dockerfile:

```bash
# Build image
docker build -t frozen-inventory .

# Run container
docker run -d \
  --name frozen-inventory \
  -p 3000:3000 \
  -e RAILS_ENV=production \
  -e SECRET_KEY_BASE=$(openssl rand -base64 32) \
  -v frozen-inventory-data:/rails/storage \
  frozen-inventory
```

### Docker Compose

Create `docker-compose.yml`:

```yaml
version: '3.8'
services:
  web:
    build: .
    ports:
      - "3000:3000"
    environment:
      - RAILS_ENV=production
      - SECRET_KEY_BASE=${SECRET_KEY_BASE}
    volumes:
      - frozen-inventory-data:/rails/storage
      - frozen-inventory-logs:/rails/log
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/ssl/certs
    depends_on:
      - web
    restart: unless-stopped

volumes:
  frozen-inventory-data:
  frozen-inventory-logs:
```

Deploy with Docker Compose:

```bash
# Create environment file
echo "SECRET_KEY_BASE=$(openssl rand -base64 32)" > .env

# Start services
docker-compose up -d

# View logs
docker-compose logs -f web
```

## Kamal Deployment

The application includes Kamal configuration for modern deployment.

### 1. Setup Kamal

```bash
# Install Kamal
gem install kamal

# Initialize configuration (already done)
# kamal init
```

### 2. Configure Deployment

Edit `config/deploy.yml`:

```yaml
service: frozen-inventory
image: frozen-inventory

servers:
  - your-server-ip

registry:
  server: your-registry.com
  username: your-username
  password:
    - DOCKER_REGISTRY_PASSWORD

env:
  clear:
    RAILS_ENV: production
  secret:
    - SECRET_KEY_BASE

volumes:
  - "frozen-inventory-storage:/rails/storage"

healthcheck:
  path: /up
  port: 3000
```

### 3. Setup Secrets

```bash
# Edit secrets file
nano .kamal/secrets

# Add required secrets
SECRET_KEY_BASE=<generate-with-rails-secret>
DOCKER_REGISTRY_PASSWORD=<your-registry-password>
```

### 4. Deploy

```bash
# Initial setup
kamal setup

# Deploy application
kamal deploy

# Check status
kamal app status

# View logs
kamal app logs -f
```

## Environment Configuration

### Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `RAILS_ENV` | Rails environment | Yes | development |
| `SECRET_KEY_BASE` | Rails secret key | Yes (prod) | Generated |
| `DATABASE_URL` | Database connection | No | SQLite file |
| `RAILS_SERVE_STATIC_FILES` | Serve static files | No (prod) | false |
| `RAILS_LOG_TO_STDOUT` | Log to stdout | No | false |
| `PORT` | Server port | No | 3000 |

### Production Secrets

Generate secure secret key:

```bash
# Generate new secret
rails secret

# Or use OpenSSL
openssl rand -base64 32
```

### SSL Configuration

For HTTPS in production:

1. **Obtain SSL Certificate** (Let's Encrypt recommended):
   ```bash
   sudo apt install certbot python3-certbot-nginx
   sudo certbot --nginx -d your-domain.com
   ```

2. **Update Nginx Configuration**:
   ```nginx
   server {
       listen 443 ssl http2;
       server_name your-domain.com;

       ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

       location / {
           proxy_pass http://127.0.0.1:3000;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto https;
       }
   }
   ```

## Database Management

### SQLite in Production

For small to medium deployments, SQLite is sufficient:

```bash
# Backup database
cp storage/production.sqlite3 backups/production-$(date +%Y%m%d).sqlite3

# Restore database
cp backups/production-20240115.sqlite3 storage/production.sqlite3
```

### Migration to PostgreSQL

For larger deployments, consider PostgreSQL:

1. **Install PostgreSQL**:
   ```bash
   sudo apt install postgresql postgresql-contrib
   ```

2. **Update Gemfile**:
   ```ruby
   gem 'pg', '~> 1.1'
   ```

3. **Update database.yml**:
   ```yaml
   production:
     adapter: postgresql
     database: frozen_inventory_production
     username: frozen_inventory
     password: <%= ENV['DATABASE_PASSWORD'] %>
     host: localhost
   ```

### Backup Strategy

Automated backup script:

```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="/var/backups/frozen-inventory"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup SQLite database
cp /var/www/frozen-inventory/storage/production.sqlite3 \
   $BACKUP_DIR/database_$DATE.sqlite3

# Backup uploaded files
tar -czf $BACKUP_DIR/storage_$DATE.tar.gz \
   /var/www/frozen-inventory/storage/

# Keep only last 30 days
find $BACKUP_DIR -name "*.sqlite3" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo "Backup completed: $DATE"
```

Set up daily backups:

```bash
# Add to crontab
crontab -e

# Add line:
0 2 * * * /var/www/frozen-inventory/scripts/backup.sh
```

## Monitoring and Maintenance

### Log Management

```bash
# View application logs
tail -f log/production.log

# Log rotation with logrotate
sudo nano /etc/logrotate.d/frozen-inventory
```

```
/var/www/frozen-inventory/log/*.log {
    daily
    missingok
    rotate 30
    compress
    notifempty
    copytruncate
}
```

### Health Monitoring

Create monitoring script:

```bash
#!/bin/bash
# health-check.sh

URL="http://localhost:3000/api/v1/status"
RESPONSE=$(curl -s -w "%{http_code}" $URL)

if [[ $RESPONSE == *"200" ]]; then
    echo "$(date): Application healthy"
else
    echo "$(date): Application unhealthy - Response: $RESPONSE"
    # Send alert (email, Slack, etc.)
    systemctl restart frozen-inventory
fi
```

### Performance Monitoring

Monitor key metrics:

```bash
# CPU and Memory usage
htop

# Disk usage
df -h

# Application performance
curl -w "@curl-format.txt" -o /dev/null -s "http://localhost:3000/"
```

### Security Updates

Regular maintenance:

```bash
# Update system packages
sudo apt update && sudo apt upgrade

# Update Ruby gems
bundle update --conservative

# Update Docker images (if using Docker)
docker pull frozen-inventory:latest
```

## Troubleshooting

### Common Issues

1. **Port 3000 already in use**:
   ```bash
   lsof -i :3000
   kill -9 <process-id>
   ```

2. **Permission errors**:
   ```bash
   sudo chown -R www-data:www-data /var/www/frozen-inventory
   sudo chmod -R 755 /var/www/frozen-inventory
   ```

3. **Database locked errors**:
   ```bash
   # Check for zombie processes
   ps aux | grep rails

   # Restart application
   sudo systemctl restart frozen-inventory
   ```

4. **SSL certificate issues**:
   ```bash
   # Renew Let's Encrypt certificate
   sudo certbot renew
   ```

### Log Analysis

Common log patterns to watch for:

```bash
# Error patterns
grep "ERROR" log/production.log | tail -20
grep "500" log/production.log | tail -20

# Performance issues
grep "Completed.*ms" log/production.log | grep -E "[0-9]{4,}" | tail -10
```

### Recovery Procedures

1. **Application crash recovery**:
   ```bash
   sudo systemctl restart frozen-inventory
   sudo systemctl status frozen-inventory
   ```

2. **Database corruption recovery**:
   ```bash
   # Restore from backup
   cp backups/latest.sqlite3 storage/production.sqlite3
   sudo systemctl restart frozen-inventory
   ```

3. **Full system recovery**:
   ```bash
   # Stop all services
   sudo systemctl stop frozen-inventory nginx

   # Restore application
   git pull origin main
   bundle install

   # Restore database
   cp backups/latest.sqlite3 storage/production.sqlite3

   # Restart services
   sudo systemctl start frozen-inventory nginx
   ```

For additional support, refer to the [API documentation](api/README.md) and create issues in the repository.