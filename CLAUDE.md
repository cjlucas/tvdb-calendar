# Tvdbcalendar Rails Development with Native Subagents

This project uses Claude Code's native subagents to create an intelligent team of AI specialists for different aspects of Rails development.

## Project Overview

- **Application**: Tvdbcalendar
- **Rails Version**: 8.0.2
- **Ruby Version**: 3.4.5
- **Type**: Full-stack Rails application
- **Test Framework**: Minitest

## 🚨 MANDATORY PRE-COMMIT CHECKLIST 🚨

**BEFORE EVERY SINGLE COMMIT, YOU MUST:**

1. **✅ RUN LINTING**: Execute `rubocop` and fix ALL violations
   - Zero tolerance policy - fix every single violation
   - Use `rubocop -a` for safe auto-fixes, `rubocop -A` for all fixes

2. **✅ RUN TESTS**: Execute BOTH test suites during RSpec conversion
   - `rails test` - Minitest suite (temporary during conversion)
   - `bundle exec rspec` - RSpec suite (new tests)
   - 0 failures, 0 errors required in BOTH suites
   - If tests fail, fix the issues before committing

3. **✅ STAGE FILES**: Check `git status` and stage appropriate files
   - Review what you're committing with `git diff --staged`

4. **✅ COMMIT MESSAGE**: Write clear, descriptive commit message
   - Include the Claude Code footer format

5. **✅ ONLY THEN**: Commit and push your changes

**❌ NEVER COMMIT WITHOUT COMPLETING ALL 5 STEPS ❌**

This checklist is **NON-NEGOTIABLE** and must be followed for every commit.

## How to Use

Simply describe what you want to build or fix, and Claude Code will automatically coordinate the implementation using native subagents:

```bash
# Use Claude Code directly - subagents are invoked automatically
claude "Add user authentication with email confirmation"
claude "Optimize the dashboard queries that are running slowly"
claude "Create an API endpoint for mobile app integration"
```

## Subagent Architecture

The following specialist subagents work together to implement your requests:

- **Rails Architect**: Coordinates all development and makes high-level decisions (`.claude/agents/rails-architect.md`)
- **Rails Models**: Handles ActiveRecord models, migrations, and database design (`.claude/agents/rails-models.md`)
- **Rails Controllers**: Manages request handling, routing, and controller logic (`.claude/agents/rails-controllers.md`)
- **Rails Views**: Creates and maintains views, layouts, and partials (`.claude/agents/rails-views.md`)
- **Rails Stimulus**: Implements interactive features with Stimulus controllers (`.claude/agents/rails-stimulus.md`)
- **Rails Services**: Extracts business logic into service objects (`.claude/agents/rails-services.md`)
- **Rails Jobs**: Handles background processing and async tasks (`.claude/agents/rails-jobs.md`)
- **Rails Tests**: Ensures comprehensive test coverage with Minitest (`.claude/agents/rails-tests.md`)
- **Rails DevOps**: Manages deployment and production configurations (`.claude/agents/rails-devops.md`)

These subagents are automatically invoked by Claude Code when their expertise is needed. Each has specialized knowledge and follows Rails best practices.

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

### Branch Management
- **CRITICAL**: NEVER make code changes while on the master branch
- **MANDATORY**: ALWAYS check current branch before making ANY code changes
- **WORKFLOW**: Before any code modification:
  1. Check current branch with `git branch --show-current`
  2. If on master, create and switch to new feature branch immediately
  3. Use descriptive branch names (e.g., `feature/add-authentication`, `fix/user-sync-bug`)
- **Why**: Prevents accidental commits to master and maintains clean git history
- **Exception**: Only documentation updates to CLAUDE.md may be made directly on master

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
  - **⚠️ SEE MANDATORY PRE-COMMIT CHECKLIST ABOVE** - This is the definitive workflow
  - **Linting**: MANDATORY `rubocop` check before every commit - fix ALL violations
  - **Testing**: ALL tests must pass before committing - no exceptions
  - **Workflow**: Code changes → `rubocop` → fix violations → `rails test` → verify pass → commit
  - **Why**: Maintains consistent code style and prevents broken code from entering the repository
  - **Critical**: Never commit code without passing lint and tests - this is non-negotiable

## Notes

- This configuration uses Claude Code's native subagents feature
- Subagent prompts are located in `.claude/agents/`
- Update this file with project-specific conventions
- Subagents automatically learn from your codebase patterns and follow Rails best practices