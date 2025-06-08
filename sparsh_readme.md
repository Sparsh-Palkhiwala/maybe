# Maybe Finance - Self-Hosting Guide

A comprehensive guide to self-hosting Maybe Finance, the open-source personal finance application.

## Table of Contents
- [What is Maybe Finance?](#what-is-maybe-finance)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Security Setup](#security-setup)
- [Bank Account Integration](#bank-account-integration)
- [Troubleshooting](#troubleshooting)
- [Maintenance](#maintenance)
- [FAQ](#faq)

## What is Maybe Finance?

Maybe Finance is an open-source personal finance platform that helps you:
- Track all your accounts (bank, credit cards, investments)
- Categorize and analyze spending
- Monitor budgets and financial goals
- Visualize your financial data with charts
- Import data via CSV or (soon) automatic bank syncing

**Self-hosting benefits:**
- ✅ Complete data ownership and privacy
- ✅ No monthly subscription fees
- ✅ Customizable to your needs
- ✅ Works entirely offline after setup

## Prerequisites

### System Requirements
- **Operating System**: Windows, macOS, or Linux
- **RAM**: 2GB minimum (4GB recommended)
- **Storage**: 10GB available space
- **Docker**: Latest version of Docker Desktop or Docker Engine

### Required Software
1. **Docker Desktop** (easiest option)
   - **Windows/Mac**: Download from [docker.com](https://docs.docker.com/get-docker/)
   - **Linux**: Install Docker Engine via package manager

2. **Docker Compose** (usually included with Docker Desktop)

## Quick Start

### 1. Install Docker

**Windows/Mac:**
```bash
# Download and install Docker Desktop from docker.com
# Verify installation:
docker run hello-world
```

### 2. Create Project Directory

```bash
# Create a directory for your Maybe application
mkdir -p ~/maybe-finance
cd ~/maybe-finance
```

### 3. Download Configuration Files

**Option A: Download compose file directly**
```bash
curl -o compose.yml https://raw.githubusercontent.com/maybe-finance/maybe/main/compose.example.yml
```

**Option B: Use custom secure configuration**
Create a `compose.yml` file with the following content:

```yaml
# Simple Maybe Docker Compose Configuration

x-db-env: &db_env
  POSTGRES_USER: ${POSTGRES_USER:-maybe_user}
  POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-maybe_password}
  POSTGRES_DB: ${POSTGRES_DB:-maybe_production}

x-rails-env: &rails_env
  <<: *db_env
  SECRET_KEY_BASE: ${SECRET_KEY_BASE:-a7523c3d0ae56415046ad8abae168d71074a79534a7062258f8d1d51ac2f76d3c3bc86d86b6b0b307df30d9a6a90a2066a3fa9e67c5e6f374dbd7dd4e0778e13}
  SELF_HOSTED: "true"
  RAILS_FORCE_SSL: "false"
  RAILS_ASSUME_SSL: "false"
  DB_HOST: db
  DB_PORT: 5432
  REDIS_URL: redis://redis:6379/1

services:
  web:
    image: ghcr.io/maybe-finance/maybe:latest
    volumes:
      - app-storage:/rails/storage
    ports:
      - "${MAYBE_PORT:-3000}:3000"
    restart: unless-stopped
    environment:
      <<: *rails_env
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - maybe_net

  worker:
    image: ghcr.io/maybe-finance/maybe:latest
    command: bundle exec sidekiq
    restart: unless-stopped
    depends_on:
      redis:
        condition: service_healthy
    environment:
      <<: *rails_env
    networks:
      - maybe_net

  db:
    image: postgres:16
    restart: unless-stopped
    volumes:
      - postgres-data:/var/lib/postgresql/data
    environment:
      <<: *db_env
    healthcheck:
      test: [ "CMD-SHELL", "pg_isready -U $POSTGRES_USER -d $POSTGRES_DB" ]
      interval: 5s
      timeout: 5s
      retries: 5
    networks:
      - maybe_net

  redis:
    image: redis:latest
    restart: unless-stopped
    volumes:
      - redis-data:/data
    healthcheck:
      test: [ "CMD", "redis-cli", "ping" ]
      interval: 5s
      timeout: 5s
      retries: 5
    networks:
      - maybe_net

volumes:
  app-storage:
  postgres-data:
  redis-data:

networks:
  maybe_net:
    driver: bridge
```

### 4. Start the Application

```bash
# Start all services in the background
docker compose up -d

# Check if all services are running
docker compose ps

# View logs (optional)
docker compose logs -f
```

### 5. Access Maybe

Open your browser and navigate to: **http://localhost:3000**

### 6. Create Your Account

1. Click "Create your account" on the login page
2. Enter your email and password
3. Start adding your financial accounts!

## Security Setup

For enhanced security, create a `.env` file with custom credentials:

### 1. Create Environment File

```bash
# Create .env file
touch .env
```

### 2. Generate Secure Credentials

```bash
# Generate a secret key (64 characters)
openssl rand -hex 64

# Generate a secure database password
openssl rand -base64 32
```

### 3. Edit .env File

Add the following to your `.env` file:

```env
# Application secret key (replace with generated key)
SECRET_KEY_BASE=your_64_character_secret_key_here

# Database credentials
POSTGRES_USER=maybe_user
POSTGRES_DB=maybe_production
POSTGRES_PASSWORD=your_secure_db_password_here

# Optional: Change default port
MAYBE_PORT=3000

# Optional: OpenAI API key for AI features (will incur costs)
# OPENAI_ACCESS_TOKEN=sk-your-openai-api-key-here
```

### 4. Secure File Permissions

```bash
# Restrict access to .env file
chmod 600 .env
```

### 5. Restart Application

```bash
docker compose down
docker compose up -d
```

## Bank Account Integration

### Current Options

#### 1. CSV Import (Available Now)
- **Best for**: Complete control over your data
- **How**: Download CSV files from your bank and upload to Maybe
- **Pros**: Works with any bank, private, reliable
- **Cons**: Manual process

**Steps:**
1. Log into your bank's website
2. Export transaction history as CSV
3. In Maybe, go to Accounts → Import CSV
4. Upload and map your CSV columns
5. Review and confirm import

#### 2. Manual Entry
- **Best for**: Cash transactions, small account sets
- **How**: Manually add accounts and transactions
- **Pros**: Complete control
- **Cons**: Time-consuming

#### 3. Plaid Integration (Coming Soon)
- **Best for**: Automatic syncing
- **How**: Connect accounts through secure API
- **Status**: In development for self-hosted version
- **When**: Expected in next few months

### Supported Account Types
- ✅ Bank accounts (checking, savings)
- ✅ Credit cards
- ✅ Investment accounts
- ✅ Loans and mortgages
- ✅ Cash accounts
- ✅ Crypto accounts (manual entry)

## Troubleshooting

### Common Issues

#### Database Connection Errors
**Problem**: `password authentication failed for user "maybe_user"`

**Solution**:
```bash
# Stop application
docker compose down

# Remove database volume to reset
docker volume rm maybe_postgres-data

# Start fresh
docker compose up -d
```

#### Port Already in Use
**Problem**: `port 3000 already allocated`

**Solution**: Change port in `.env` file:
```env
MAYBE_PORT=3001
```

#### Services Not Starting
**Problem**: Containers failing to start

**Solution**:
```bash
# Check logs for specific service
docker compose logs web
docker compose logs db

# Restart specific service
docker compose restart web
```

#### Out of Disk Space
**Problem**: Docker volumes consuming too much space

**Solution**:
```bash
# Clean up unused Docker resources
docker system prune -a

# Remove unused volumes (careful!)
docker volume prune
```

### Getting Help
- **GitHub Issues**: [maybe-finance/maybe](https://github.com/maybe-finance/maybe/issues)
- **Discussions**: [GitHub Discussions](https://github.com/maybe-finance/maybe/discussions)
- **Documentation**: [Official Docs](https://github.com/maybe-finance/maybe/blob/main/docs/hosting/docker.md)

## Maintenance

### Regular Tasks

#### 1. Backup Your Data
```bash
# Create database backup
docker exec maybe-db-1 pg_dump -U maybe_user maybe_production > backup_$(date +%Y%m%d).sql

# Backup .env file (store securely)
cp .env .env.backup
```

#### 2. Update Maybe
```bash
# Pull latest image
docker compose pull

# Restart with new version
docker compose up -d
```

#### 3. Monitor Disk Usage
```bash
# Check Docker disk usage
docker system df

# Check volume sizes
docker volume ls
```

### Automated Backup Script
Create a `backup.sh` file:

```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups"

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup database
docker exec maybe-db-1 pg_dump -U maybe_user maybe_production > $BACKUP_DIR/maybe_backup_$DATE.sql

# Backup environment file
cp .env $BACKUP_DIR/.env_backup_$DATE

echo "Backup completed: $BACKUP_DIR/maybe_backup_$DATE.sql"
```

Make it executable:
```bash
chmod +x backup.sh
```

## FAQ

### General Questions

**Q: Is Maybe Finance free?**
A: Yes, Maybe is completely open-source and free to self-host.

**Q: How secure is self-hosting?**
A: Very secure when properly configured. Your data never leaves your server.

**Q: Can I access Maybe from my phone?**
A: Yes, the web interface is mobile-responsive. Access via your browser.

**Q: Does Maybe work offline?**
A: Yes, once set up, Maybe works completely offline.

### Technical Questions

**Q: What databases does Maybe use?**
A: PostgreSQL for data storage, Redis for caching and background jobs.

**Q: Can I run Maybe on a Raspberry Pi?**
A: Yes, but ensure you have enough RAM (4GB recommended).

**Q: How do I change the default port?**
A: Set `MAYBE_PORT=your_port` in your `.env` file.

**Q: Can multiple users access the same instance?**
A: Currently, Maybe is designed as a single-user application.

### Data Questions

**Q: How do I migrate from another finance app?**
A: Export your data as CSV from the other app and import into Maybe.

**Q: What CSV format does Maybe expect?**
A: Standard banking CSV with columns: Date, Description, Amount, Category (optional).

**Q: Can I connect crypto exchanges?**
A: Not automatically yet, but you can import crypto transactions via CSV.

**Q: How often should I import data?**
A: Weekly or monthly CSV imports work well for most users.

### Troubleshooting Questions

**Q: What if I forget my Maybe password?**
A: Currently, you'll need to reset the database or create a new account.

**Q: The app won't start after an update?**
A: Try `docker compose down && docker compose pull && docker compose up -d`

**Q: How do I completely reset Maybe?**
A: Stop containers, remove volumes: `docker compose down && docker volume prune`

## Additional Resources

- **Official Repository**: https://github.com/maybe-finance/maybe
- **Documentation**: https://github.com/maybe-finance/maybe/tree/main/docs
- **Docker Hub**: https://github.com/maybe-finance/maybe/pkgs/container/maybe
- **Community**: https://github.com/maybe-finance/maybe/discussions

---

**⚠️ Important Notes:**
- Always backup your data before major updates
- Keep your `.env` file secure and never commit it to version control
- Monitor your system resources when running multiple Docker services
- Consider setting up automatic backups for production use

Happy self-hosting! 🚀