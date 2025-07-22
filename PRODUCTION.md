# Production Deployment Guide

This guide covers deploying the TVDB Calendar service to production using Docker.

## Prerequisites

- Docker runtime environment
- TheTVDB API key ([get one here](https://thetvdb.com/dashboard))
- Secret key base for production (see below)

## Required Environment Variables

### 1. SECRET_KEY_BASE
Used for securing sessions, cookies, and other cryptographic operations.

**Generate a secret key base:**
```bash
# Generate a new secret key base for production
rails secret
```

### 2. TVDB_API_KEY
Your TheTVDB API key for accessing the TVDB API.

**Get your API key:**
1. Sign up at [TheTVDB](https://thetvdb.com/dashboard)
2. Go to Account → API Access
3. Create a new API key

### 3. PostgreSQL Database Configuration

**Recommended for production (with development defaults):**
- `DATABASE_HOST` - PostgreSQL host (default: `localhost`)
- `DATABASE_PORT` - PostgreSQL port (default: `5432`)
- `DATABASE_USERNAME` - PostgreSQL username (default: `tvdbcalendar`)
- `DATABASE_PASSWORD` - PostgreSQL password (default: `tvdbcalendar`)

**Note:** While defaults are provided for development/testing, you should explicitly set these for production deployment.

The application will create and use these specific database names:
- `tvdb_calendar_production` - Main application data
- `tvdb_calendar_cache_production` - Cache storage
- `tvdb_calendar_queue_production` - Background job queue
- `tvdb_calendar_cable_production` - WebSocket connections

### 4. Optional Environment Variables
- `RAILS_LOG_LEVEL`: Set logging level (default: `info`, options: `debug`, `info`, `warn`, `error`)
- `RAILS_MAX_THREADS`: Maximum number of threads (default: `5`)

## Docker Image

The application is automatically built and published to GitHub Container Registry when tags are pushed.

**Available tags:**
- `latest` - Latest stable release
- `v1.1` - Specific version tags (matches git tags)

## Deployment Options

### Option 1: Docker Run (Simple)

```bash
docker run -d \
  -p 3000:80 \
  -e SECRET_KEY_BASE=your_secret_key_base_here \
  -e TVDB_API_KEY=your_tvdb_api_key_here \
  -e DATABASE_HOST=your_postgres_host \
  -e DATABASE_PORT=5432 \
  -e DATABASE_USERNAME=your_postgres_user \
  -e DATABASE_PASSWORD=your_postgres_password \
  --name tvdb-calendar \
  ghcr.io/cjlucas/tvdb-calendar:latest
```

### Option 2: Docker Compose

Create a `docker-compose.yml` file:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: tvdb_calendar
      POSTGRES_PASSWORD: ${DATABASE_PASSWORD}
      POSTGRES_DB: tvdb_calendar_production
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U tvdb_calendar"]
      interval: 30s
      timeout: 10s
      retries: 3

  app:
    image: ghcr.io/cjlucas/tvdb-calendar:latest
    ports:
      - "3000:80"
    environment:
      - SECRET_KEY_BASE=${SECRET_KEY_BASE}
      - TVDB_API_KEY=${TVDB_API_KEY}
      - DATABASE_HOST=postgres
      - DATABASE_PORT=5432
      - DATABASE_USERNAME=tvdb_calendar
      - DATABASE_PASSWORD=${DATABASE_PASSWORD}
      - RAILS_LOG_LEVEL=info
    depends_on:
      postgres:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/up"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_data:
```

Create a `.env` file:
```bash
SECRET_KEY_BASE=your_secret_key_base_here
TVDB_API_KEY=your_tvdb_api_key_here
DATABASE_PASSWORD=your_postgres_password_here
```

Deploy:
```bash
docker-compose up -d
```

### Option 3: Kubernetes

Create Kubernetes manifests:

```yaml
# tvdb-calendar-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: tvdb-calendar-secrets
type: Opaque
data:
  secret-key-base: <base64-encoded-secret-key-base>
  tvdb-api-key: <base64-encoded-api-key>

---
# tvdb-calendar-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tvdb-calendar
spec:
  replicas: 2
  selector:
    matchLabels:
      app: tvdb-calendar
  template:
    metadata:
      labels:
        app: tvdb-calendar
    spec:
      containers:
      - name: tvdb-calendar
        image: ghcr.io/cjlucas/tvdb-calendar:latest
        ports:
        - containerPort: 80
        env:
        - name: SECRET_KEY_BASE
          valueFrom:
            secretKeyRef:
              name: tvdb-calendar-secrets
              key: secret-key-base
        - name: TVDB_API_KEY
          valueFrom:
            secretKeyRef:
              name: tvdb-calendar-secrets
              key: tvdb-api-key
        volumeMounts:
        - name: storage
          mountPath: /rails/storage
        livenessProbe:
          httpGet:
            path: /up
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /up
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: storage
        persistentVolumeClaim:
          claimName: tvdb-calendar-pvc
```

## Health Checks

The application provides a health check endpoint at `/up` that returns:
- `200 OK` when the application is healthy
- `500 Internal Server Error` when there are issues

## Storage

The application uses PostgreSQL for all data storage:
- **Main database**: Application data (users, favorites, etc.)
- **Cache database**: Rails cache storage 
- **Queue database**: Background job queue
- **Cable database**: WebSocket connections

**Important:** Ensure your PostgreSQL instance has persistent storage and regular backups configured.

## Monitoring

### Logs
Application logs are sent to STDOUT and can be viewed with:
```bash
docker logs tvdb-calendar
```

### Metrics
The application includes built-in Rails performance monitoring. Access logs provide request timing information.

## Security Considerations

1. **HTTPS**: The application is configured to force SSL in production
2. **Secrets**: Never commit production secrets to version control
3. **Updates**: Regularly update to the latest image version
4. **Network**: Consider running behind a reverse proxy (nginx, traefik, etc.)

## Troubleshooting

### Common Issues

**Container won't start:**
- Check that `SECRET_KEY_BASE` is set correctly
- Verify `TVDB_API_KEY` is valid
- Ensure `DATABASE_PASSWORD` is set and PostgreSQL is accessible
- Check container logs: `docker logs tvdb-calendar`

**Database connection errors:**
- Verify PostgreSQL is running and accessible
- For production, set database environment variables: `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`
- Development defaults: host=localhost, port=5432, username=tvdbcalendar, password=tvdbcalendar
- The application automatically runs `rails db:prepare` on startup
- Ensure the PostgreSQL user has permissions to create databases or manually create:
  - `tvdb_calendar_production`
  - `tvdb_calendar_cache_production` 
  - `tvdb_calendar_queue_production`
  - `tvdb_calendar_cable_production`

**API errors:**
- Verify your TVDB API key is active and valid
- Check TVDB API status: https://status.thetvdb.com/

### Support

For issues related to:
- **Application bugs**: Create an issue in the GitHub repository
- **TVDB API**: Check [TheTVDB documentation](https://thetvdb.com/api-information)
- **Docker deployment**: Consult Docker documentation

## Backup

Regular backups of your PostgreSQL databases are recommended:

```bash
# Backup all databases
pg_dump -h your_postgres_host -U postgres tvdb_calendar_production > backup-$(date +%Y%m%d)-main.sql
pg_dump -h your_postgres_host -U postgres tvdb_calendar_cache_production > backup-$(date +%Y%m%d)-cache.sql
pg_dump -h your_postgres_host -U postgres tvdb_calendar_queue_production > backup-$(date +%Y%m%d)-queue.sql
pg_dump -h your_postgres_host -U postgres tvdb_calendar_cable_production > backup-$(date +%Y%m%d)-cable.sql

# Restore databases
psql -h your_postgres_host -U postgres tvdb_calendar_production < backup-YYYYMMDD-main.sql
psql -h your_postgres_host -U postgres tvdb_calendar_cache_production < backup-YYYYMMDD-cache.sql
psql -h your_postgres_host -U postgres tvdb_calendar_queue_production < backup-YYYYMMDD-queue.sql
psql -h your_postgres_host -U postgres tvdb_calendar_cable_production < backup-YYYYMMDD-cable.sql
```