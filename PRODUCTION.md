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

### 3. Optional Environment Variables
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
  -v tvdb_calendar_data:/rails/storage \
  --name tvdb-calendar \
  ghcr.io/cjlucas/tvdb-calendar:latest
```

### Option 2: Docker Compose

Create a `docker-compose.yml` file:

```yaml
version: '3.8'

services:
  app:
    image: ghcr.io/cjlucas/tvdb-calendar:latest
    ports:
      - "3000:80"
    environment:
      - SECRET_KEY_BASE=${SECRET_KEY_BASE}
      - TVDB_API_KEY=${TVDB_API_KEY}
      - RAILS_LOG_LEVEL=info
    volumes:
      - app_storage:/rails/storage
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/up"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  app_storage:
```

Create a `.env` file:
```bash
SECRET_KEY_BASE=your_secret_key_base_here
TVDB_API_KEY=your_tvdb_api_key_here
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

The application uses SQLite databases stored in `/rails/storage/`:
- `production.sqlite3` - Main application database
- `production_cache.sqlite3` - Cache storage
- `production_queue.sqlite3` - Background job queue
- `production_cable.sqlite3` - WebSocket connections

**Important:** Mount the `/rails/storage` directory as a persistent volume to retain data between container restarts.

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
- Check container logs: `docker logs tvdb-calendar`

**Database migration errors:**
- The application automatically runs `rails db:prepare` on startup
- If you need to reset the database, delete the storage volume

**API errors:**
- Verify your TVDB API key is active and valid
- Check TVDB API status: https://status.thetvdb.com/

### Support

For issues related to:
- **Application bugs**: Create an issue in the GitHub repository
- **TVDB API**: Check [TheTVDB documentation](https://thetvdb.com/api-information)
- **Docker deployment**: Consult Docker documentation

## Backup

Regular backups of the `/rails/storage` directory are recommended:

```bash
# Backup
docker run --rm -v tvdb_calendar_data:/data -v $(pwd):/backup alpine tar czf /backup/tvdb-calendar-backup-$(date +%Y%m%d).tar.gz /data

# Restore
docker run --rm -v tvdb_calendar_data:/data -v $(pwd):/backup alpine tar xzf /backup/tvdb-calendar-backup-YYYYMMDD.tar.gz -C /
```