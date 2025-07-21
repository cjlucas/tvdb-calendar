# Docker Deployment Setup

This repository automatically builds and publishes Docker images to GitHub Container Registry (ghcr.io) using GitHub Actions.

## 🚀 Automatic Builds

### When Images Are Built

1. **Master Branch Commits**: Every commit to `master` creates an image tagged as `master`
2. **Version Tags**: Any git tag creates an image with that tag name + `latest`

### Image Registry

Images are published to: `ghcr.io/cjlucas/tvdb-calendar`

### Supported Platforms

- `linux/amd64` (x86_64)
- `linux/arm64` (ARM64/Apple Silicon)

## 📋 Required Repository Secrets

For email notifications on build failures, configure these secrets in your repository settings:

- `MAIL_USERNAME`: Your Gmail address (e.g., `your-email@gmail.com`)
- `MAIL_PASSWORD`: Gmail app password (not your regular password)
- `MAIL_TO`: Email address to receive notifications (e.g., `chris@example.com`)

### Setting Up Gmail App Password

1. Enable 2-factor authentication on your Gmail account
2. Go to Google Account settings → Security
3. Under "2-Step Verification", click "App passwords"
4. Generate a new app password for "GitHub Actions"
5. Use this app password as `MAIL_PASSWORD` secret

## 🏷️ Tagging Strategy

### Master Branch
```bash
git push origin master
# Creates: ghcr.io/cjlucas/tvdb-calendar:master
```

### Version Releases
```bash
git tag 1.0
git push origin 1.0
# Creates: 
#   ghcr.io/cjlucas/tvdb-calendar:1.0
#   ghcr.io/cjlucas/tvdb-calendar:latest
```

```bash
git tag 2.1
git push origin 2.1
# Creates:
#   ghcr.io/cjlucas/tvdb-calendar:2.1
#   ghcr.io/cjlucas/tvdb-calendar:latest (updated)
```

## 🐳 Using the Images

### Pull and Run Latest Version
```bash
docker pull ghcr.io/cjlucas/tvdb-calendar:latest
docker run -d -p 80:80 \
  -e RAILS_MASTER_KEY=<your-master-key> \
  -e TVDB_API_KEY=<your-tvdb-key> \
  --name tvdb-calendar \
  ghcr.io/cjlucas/tvdb-calendar:latest
```

### Pull Specific Version
```bash
docker pull ghcr.io/cjlucas/tvdb-calendar:1.0
docker run -d -p 80:80 \
  -e RAILS_MASTER_KEY=<your-master-key> \
  -e TVDB_API_KEY=<your-tvdb-key> \
  --name tvdb-calendar \
  ghcr.io/cjlucas/tvdb-calendar:1.0
```

### Use Master Branch (Development)
```bash
docker pull ghcr.io/cjlucas/tvdb-calendar:master
docker run -d -p 80:80 \
  -e RAILS_MASTER_KEY=<your-master-key> \
  -e TVDB_API_KEY=<your-tvdb-key> \
  --name tvdb-calendar \
  ghcr.io/cjlucas/tvdb-calendar:master
```

## 🔧 Required Environment Variables

- `RAILS_MASTER_KEY`: Your Rails master key (from `config/master.key`)
- `TVDB_API_KEY`: Your TheTVDB API key
- `JOB_CONCURRENCY`: (Optional) Number of background job workers (default: 1)

## 📊 Build Status

Check the Actions tab in GitHub to monitor build status:
https://github.com/cjlucas/tvdb-calendar/actions

## 🚨 Failure Notifications

If a Docker build fails, you'll receive an email notification with:
- Repository and build details
- Link to the failed workflow run
- Commit information and timestamp

## 🏗️ Workflow Features

- **Multi-platform builds**: Supports both AMD64 and ARM64 architectures
- **Build caching**: Uses GitHub Actions cache for faster builds
- **Automatic tagging**: Smart tagging based on branch/tag names
- **Email notifications**: Get notified of build failures
- **Security**: Uses GitHub's built-in authentication tokens