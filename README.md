# PredKit Database

A Dockerized PostgreSQL 18 setup with advanced search and AI capabilities for the PredKit project.

## Features

- **PostgreSQL 18** (Debian Trixie base)
- **pg_search** - Full-text search with BM25 algorithm (ParadeDB)
- **pgai** - AI/ML capabilities (Timescale AI)
- **Health Checks** - Container health monitoring
- **Backup Support** - Volume-mounted backup directory

## Quick Start

1. **Clone and Setup**
   ```bash
   cd /path/to/PredKit/db
   cp env.example .env
   # Edit .env with your preferred credentials
   ```

2. **Build and Run**
   ```bash
   # Start PostgreSQL
   docker-compose up -d postgres
   ```

3. **Verify Installation**
   ```bash
   # Check container health
   docker-compose ps
   
   # Connect to database
   docker-compose exec postgres psql -U predkit_user -d predkit
   ```

4. **Verify Extensions**
   ```sql
   -- Check installed extensions
   SELECT extname, extversion FROM pg_extension 
   WHERE extname IN ('pg_search', 'ai');
   ```

## Configuration

### Environment Variables

Copy `env.example` to `.env` and customize:

```bash
# Database
POSTGRES_DB=predkit
POSTGRES_USER=predkit_user
POSTGRES_PASSWORD=your_secure_password
POSTGRES_PORT=5432
```

## Extensions Overview

### pg_search (ParadeDB)
- **Purpose**: Full-text search with BM25 algorithm
- **Documentation**: [ParadeDB Docs](https://docs.paradedb.com/)

### pgai (Timescale AI)
- **Purpose**: AI/ML capabilities directly in PostgreSQL
- **Use Cases**: Vector operations, embeddings, ML model integration
- **Documentation**: [Timescale AI Docs](https://github.com/timescale/pgai)

## Development

### Local Development
```bash
# Start in development mode
docker-compose up -d

# View logs
docker-compose logs -f postgres

# Access database shell
docker-compose exec postgres psql -U predkit_user -d predkit
```

### Backup and Restore
```bash
# Create backup
docker-compose exec postgres pg_dump -U predkit_user predkit > backups/backup_$(date +%Y%m%d_%H%M%S).sql

# Restore backup
docker-compose exec -T postgres psql -U predkit_user predkit < backups/your_backup.sql
```

### Rebuilding
```bash
# Rebuild after Dockerfile changes
docker-compose build --no-cache postgres
docker-compose up -d postgres
```

## Troubleshooting

### Common Issues

1. **Extensions not loading**
   - Ensure container built successfully: `docker-compose logs postgres`
   - Check extension installation: `SELECT * FROM pg_available_extensions WHERE name LIKE '%search%' OR name LIKE '%ai%';`
   - For pg_search issues, verify Rust/pgrx installation in build logs
   - Check shared_preload_libraries setting: `SHOW shared_preload_libraries;`

2. **Connection refused**
   - Wait for health check: `docker-compose ps`
   - Check port mapping: `docker-compose port postgres 5432`

3. **Permission errors**
   - Verify volume permissions: `ls -la` in project directory
   - Check PostgreSQL logs: `docker-compose logs postgres`

### Health Checks

The PostgreSQL container includes health checks:
```bash
# Check container health
docker-compose ps

# Manual health check
docker-compose exec postgres pg_isready -U predkit_user -d predkit
```
