# TVDB Calendar Generator

A simple Rails application that generates ICS calendar files from your TheTVDB favorite series, showing upcoming episodes.

## Features

- **Simple UX**: Just enter your TheTVDB PIN and get a calendar link
- **Real-time Sync**: Watch sync progress with live updates via ActionCable
- **Automatic Updates**: Background jobs sync your data every 5 minutes
- **ICS Format**: Standard calendar format compatible with Google Calendar, Apple Calendar, Outlook, etc.
- **Episode Details**: Shows series name, episode title, season/episode numbers, and IMDB links

## Prerequisites

- Ruby 3.2.2
- Rails 8.0.2
- SQLite3
- A TheTVDB account with an API key

## Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd tvdbcalendar
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env.development.local
   ```
   
   Edit `.env` and add your TheTVDB API key:
   ```
   TVDB_API_KEY=your_api_key_here
   ```

4. **Set up the database**
   ```bash
   rails db:create
   rails db:migrate
   ```

5. **Start the application**
   ```bash
   rails server
   ```

   The app will be available at `http://localhost:3000`

6. **Start background jobs (optional for development)**
   ```bash
   rails solid_queue:start
   ```

## How to Use

1. **Get your TheTVDB PIN**
   - Go to [TheTVDB Dashboard](https://thetvdb.com/dashboard)
   - Navigate to Account → API Access
   - Copy your PIN

2. **Generate your calendar**
   - Visit the application homepage
   - Enter your PIN
   - Wait for sync to complete (first time may take a while)
   - Copy the provided calendar URL

3. **Subscribe to the calendar**
   - **Google Calendar**: Add calendar → From URL → paste the link
   - **Apple Calendar**: File → New Calendar Subscription → paste the link
   - **Outlook**: Add calendar → From internet → paste the link

## Testing

Run the test suite:
```bash
rails test
```

## Background Jobs

The application uses SolidQueue for background processing:
- **User Sync Job**: Runs every 5 minutes to update user data that hasn't been synced in over an hour
- **Recurring Jobs**: Configured in `config/recurring.yml`

## Configuration

### Environment Variables
- `TVDB_API_KEY`: Your TheTVDB API key (required)
- `JOB_CONCURRENCY`: Number of job worker processes (default: 1)

### Queue Configuration
- Queue settings: `config/queue.yml`
- Recurring jobs: `config/recurring.yml`

## API Documentation

### Endpoints
- `GET /`: Homepage with PIN input form
- `POST /users`: Create/lookup user and start sync
- `GET /calendar/:pin`: Download ICS calendar file

### ICS Format
Each episode appears as an all-day event with:
- **Title**: Series name (+ "Season Finale" if applicable)
- **Location**: Episode title and code (e.g., "Episode Name - (S01E05)")
- **Description**: IMDB link (if available)
- **Date**: Episode air date

## Development

### Key Components
- **Models**: User, Series, Episode
- **Services**: TvdbClient, UserSyncService, IcsGenerator
- **Jobs**: UserSyncJob (scheduled every 5 minutes)
- **Controllers**: HomeController, UsersController, CalendarController
- **Channels**: SyncChannel (ActionCable for real-time updates)

### Architecture
- Users are identified by their TheTVDB PIN (no PII stored)
- Series and episodes are synced from TheTVDB API
- Real-time sync progress via ActionCable WebSockets
- Background sync every 5 minutes for stale data (>1 hour old)

## Deployment

The application is ready for deployment with:
- Kamal configuration (`config/deploy.yml`)
- Docker support (`Dockerfile`)
- Production-ready queue and cache configuration

## License

This project is available as open source.
