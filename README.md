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

## Testing

```bash
rails test
```

