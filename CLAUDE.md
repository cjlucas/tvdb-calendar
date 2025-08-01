# Tvdbcalendar Rails Development with ClaudeOnRails

This project uses ClaudeOnRails to create an intelligent swarm of AI agents specialized in different aspects of Rails development.

## Project Overview

- **Application**: Tvdbcalendar
- **Rails Version**: 8.0.2
- **Ruby Version**: 3.2.2
- **Type**: Full-stack Rails application
- **Test Framework**: Minitest

## How to Use

Simply describe what you want to build or fix, and the swarm will automatically coordinate the implementation:

```bash
# Start the swarm
claude-swarm orchestrate

# Then just describe your task
claude "Add user authentication with email confirmation"
claude "Optimize the dashboard queries that are running slowly"
claude "Create an API endpoint for mobile app integration"
```

## Swarm Architecture

The following specialized agents work together to implement your requests:

- **Architect**: Coordinates all development and makes high-level decisions
- **Models**: Handles ActiveRecord models, migrations, and database design
- **Controllers**: Manages request handling, routing, and controller logic
- **Views**: Creates and maintains views, layouts, and partials
- **Stimulus**: Implements interactive features with Stimulus controllers
- **Services**: Extracts business logic into service objects
- **Jobs**: Handles background processing and async tasks
- **Tests**: Ensures comprehensive test coverage with Minitest
- **DevOps**: Manages deployment and production configurations

## Project Conventions

### Code Style
- Follow Rails conventions and best practices
- Use RuboCop for Ruby style enforcement
- Prefer clarity over cleverness
- Write self-documenting code

### RuboCop Linting
- **CRITICAL**: ALL generated code MUST pass RuboCop linting
- **MANDATORY**: ALWAYS run `rubocop` before committing ANY code changes
- Fix all violations before committing code - NO EXCEPTIONS
- Follow the project's `.rubocop.yml` configuration
- **Why**: Consistent code style across the entire codebase, automated CI checks will fail with violations
- **Commands**: 
  - Check: `rubocop`
  - Auto-fix: `rubocop -a` (safe corrections only)
  - Auto-fix all: `rubocop -A` (includes unsafe corrections)
- **Workflow**: Code changes → `rubocop` → fix violations → commit

#### Common RuboCop Violations to Avoid
Write code that follows these rules from the start to avoid lint fixes:

1. **String Literals** (`Style/StringLiterals`)
   - Use double-quoted strings: `"series.id"` not `'series.id'`
   - Exception: Use single quotes only to avoid escaping

2. **Trailing Empty Lines** (`Layout/TrailingEmptyLines`)
   - Files must end with exactly one newline
   - Always add `\n` at end of files

3. **Array Bracket Spacing** (`Layout/SpaceInsideArrayLiteralBrackets`)
   - No spaces inside brackets: `[:password, :email]` 
   - Not: `[ :password, :email ]`

4. **Method Length** (`Metrics/MethodLength`)
   - Keep methods under 10-15 lines typically

5. **Line Length** (`Layout/LineLength`)
   - Keep lines under 120 characters

6. **Hash Syntax** (`Style/HashSyntax`)
   - Use new syntax: `{ key: value }` not `{ :key => value }`

### Testing
- Minitest for all tests
- Fixtures or factories for test data
- Integration tests for user flows
- Unit tests for models and services

### Git Workflow
- Feature branches for new work
- Descriptive commit messages
- PR reviews before merging
- Keep main branch deployable

### Git Commit/Push Policy
- **CRITICAL**: NEVER commit or push code without explicit developer consent
- **ALWAYS** ask permission before running `git commit` or `git push`
- Developer must explicitly request commits/pushes with phrases like:
  - "commit this"
  - "push these changes"
  - "commit and push"
- **Exception**: Only commit/push when directly instructed by the developer
- **Why**: Developers need control over their git history and when changes go to remote repositories

## Custom Patterns

### Privacy and Security
- **User Identification**: ALWAYS use TheTVDB PINs instead of database user IDs in:
  - Routes (e.g., `/calendar/:pin` not `/calendar/:user_id`)
  - Frontend JavaScript (user_pin not user_id)
  - ActionCable channels (user_pin parameter)
  - Background job parameters
  - API responses (user_pin field)
- **Why**: Sequential user IDs are easily guessable and expose user data to unauthorized access
- **Implementation**: Use `User.find_by!(pin: params[:pin])` in controllers, pass PINs to jobs/channels

- **PIN Security**: Treat TheTVDB PINs like passwords - NEVER log actual PIN values
  - Use database user IDs for logging instead: `"Starting sync for user ID #{@user.id}"`
  - Frontend: Log actions without PIN values: `"PIN entered"` not `"PIN entered: #{pin}"`
  - ActionCable: Log channel subscriptions without PINs: `"User subscribed to channel"`
  - **Why**: PINs are sensitive authentication credentials that could be misused if exposed in logs
  - **Exception**: PINs can be used functionally (API calls, channel names) but not in log messages

### Service Objects
```yaml
Services:
  Pattern: Command pattern with Result objects
  Location: app/services/
  Naming: VerbNoun (e.g., CreateOrder, SendEmail)
  Testing: Unit tests with mocked dependencies
```

### TheTVDB API
- **Authentication**: ALL endpoints require bearer tokens for authentication
  - **Token Required**: ALL API calls (user favorites, series details, episode data, etc.)
  - **Implementation**: TvdbClient must authenticate for ALL API requests
  - **Why**: TheTVDB API requires authentication for all data access

### Development & Testing
- **Force Sync Flag**: Sync services and jobs accept a `force: true` parameter to bypass time-based sync limits
  - **UserSyncService**: `UserSyncService.new(user, force: true)` - ignores 12-hour series sync limits
  - **UserSyncIndividualJob**: `UserSyncIndividualJob.perform(user_pin, force: true)` - forces immediate sync
  - **UserSyncJob**: `UserSyncJob.perform(force: true)` - syncs all users regardless of last sync time
  - **Use Case**: Useful for development and testing when you need to re-sync data without waiting for time limits
  - **Why**: Development workflows often require immediate data refresh for testing changes

- **Test Coverage**: ALWAYS add comprehensive tests for ALL backend changes
  - **Requirement**: Every service, job, model, and controller change MUST include corresponding tests
  - **Test Types**: Unit tests for logic, integration tests for workflows, edge case coverage
  - **Why**: Ensures code quality, prevents regressions, and documents expected behavior
  - **Critical**: Never commit backend changes without tests - this is non-negotiable

- **Code Quality**: ALWAYS run linting and tests before committing ANY code
  - **Linting**: MANDATORY `rubocop` check before every commit - fix ALL violations
  - **Testing**: ALL tests must pass before committing - no exceptions
  - **Workflow**: Code changes → `rubocop` → fix violations → `rails test` → verify pass → commit
  - **Why**: Maintains consistent code style and prevents broken code from entering the repository
  - **Critical**: Never commit code without passing lint and tests - this is non-negotiable

## Notes

- This configuration was generated by ClaudeOnRails
- Customize agent prompts in `.claude-on-rails/prompts/`
- Update this file with project-specific conventions
- The swarm learns from your codebase patterns