# TVDB Calendar Generator

Rails application that generates ICS calendar files from your TheTVDB favorite series.

## Setup

**Prerequisites:**
- Ruby 3.2.2
- Rails 8.0.2
- TheTVDB API key

**Installation:**
```bash
git clone <repository-url>
cd tvdbcalendar
bundle install
cp .env.example .env.development.local
```

**Configuration:**
Edit `.env.development.local` and add your TheTVDB API key:
```
TVDB_API_KEY=your_api_key_here
```

**Database:**
```bash
rails db:create
rails db:migrate
```

**Run:**
```bash
rails server
# Optional: rails solid_queue:start
```

## Usage

1. Get your PIN from [TheTVDB Dashboard](https://thetvdb.com/dashboard) → Account → API Access
2. Enter PIN at `http://localhost:3000`
3. Copy the generated calendar URL
4. Add to your calendar app (Google Calendar, Apple Calendar, etc.)

## Production Deployment

For production deployment using Docker, see [PRODUCTION.md](PRODUCTION.md).

**Quick Docker deployment:**
```bash
docker run -d \
  -p 3000:80 \
  -e SECRET_KEY_BASE=your_secret_key_base \
  -e TVDB_API_KEY=your_tvdb_api_key \
  -e DATABASE_HOST=your_postgres_host \
  -e DATABASE_PORT=5432 \
  -e DATABASE_USERNAME=your_postgres_user \
  -e DATABASE_PASSWORD=your_postgres_password \
  ghcr.io/cjlucas/tvdb-calendar:latest
```

## Testing

```bash
rails test
```

