# Billetto Events App

> This README was generated with the assistance of AI.

A Ruby on Rails application for browsing events imported from Billetto, signing in with Clerk, and upvoting or downvoting events. Vote changes are recorded with Rails Event Store.

**Live demo:** [billetto-app-lgv4.onrender.com](https://billetto-app-lgv4.onrender.com/)

## Assignment details

The assignment documents and API reference are included in the repository:

- [Assignment instructions](doc/Assignment%20Instructions%20%281%29%20%281%29%20%281%29%20%282%29%20%282%29.pdf)
- [Rails assignment requirements](doc/billetto_rails_test.md%20%283%29%20%281%29%20%281%29%20%281%29%20%283%29%20%282%29.pdf)
- [Billetto developer guide](doc/Developer%27s%20Guide%20-%20billetto%20%282%29%20%281%29%20%281%29%20%281%29%20%281%29%20%281%29%20%282%29.pdf)

## Features

- Event listing ordered by start date, with 10 events per page.
- Event details including location, organiser, dates, availability, image, price, and a link to Billetto.
- Clerk sign-in, registration, and logout.
- Authenticated upvotes and downvotes, with current totals and the user's selected vote.
- Background imports when Sidekiq starts and every five minutes.
- Stored vote events for an audit history.

## Technology

| Component | Implementation |
| --- | --- |
| Language and framework | Ruby 3.3.3, Rails 8.1.4 |
| Database | PostgreSQL |
| Background jobs | Active Job with Sidekiq and sidekiq-cron |
| Queue storage | Redis |
| Authentication | Clerk Ruby SDK and Clerk JavaScript SDK |
| Event history | Rails Event Store 3.2 |
| Views and assets | ERB, CSS, Propshaft |
| Pagination | will_paginate |
| External API | Billetto public events API through RestClient |
| Application server | Puma, with Thruster in Docker |
| Tests | RSpec, FactoryBot, Shoulda Matchers |

## Architecture

```mermaid
flowchart TD
    Browser[Browser] --> Rails[Rails controllers and ERB views]
    Browser <--> Clerk[Clerk authentication]
    Rails --> DB[(PostgreSQL)]
    Rails --> Votes[Event voting methods]
    Votes --> DB
    Votes --> Store[Rails Event Store]
    Store --> DB
    Schedule[Sidekiq startup and five-minute schedule] --> Job[FetchEventJob]
    Job --> Queue[(Redis queue)]
    Queue --> Worker[Sidekiq worker]
    Worker --> Import[Billetto::LoadDataService]
    Import --> API[Billetto public API]
    Import --> DB
```

### Import flow

`FetchEventJob` calls `Billetto::LoadDataService`. The service requests pages from `/api/v3/public/events` using an `after` cursor, processes each page, and stops when `has_more` is false. Events are created or updated by `external_id`.

The importer strips HTML from descriptions, builds a display location, extracts organiser information, and retains the original response in `billetto_data`. The current price representation stores the API's amount in cents and currency as a string.

Sidekiq loads `config/schedule.yml` at startup and also enqueues an immediate import. Active Job uses the `:sidekiq` adapter. The worker listens to `critical`, `default`, and `low` queues with concurrency set to five.

### Authentication and voting

Event browsing is public. Voting actions check the Clerk session and redirect unauthenticated visitors with a login message. Clerk user IDs are stored as strings on vote records; there is no local user model.

`Event#up_vote` and `Event#down_vote` update an `EventVote` and publish an `EventUpvoted` or `EventDownvoted` event inside a database transaction. Repeating the same vote is a no-op; choosing the opposite vote updates the existing selection. Events are published to `Eventvoted$<event_id>`.

Displayed totals come from `event_votes`. Rails Event Store holds the vote history; the current implementation does not rebuild vote counts from that history.

### Main files

| Path | Responsibility |
| --- | --- |
| `app/controllers/events_controller.rb` | Listing, details, and authenticated vote actions |
| `app/models/event.rb` | Event validation, vote changes, counts, and event publication |
| `app/models/event_vote.rb` | Current user vote and validation |
| `app/models/event_upvoted.rb`, `event_downvoted.rb` | Domain event classes |
| `app/jobs/fetch_event_job.rb` | Background import entry point |
| `app/services/billetto/load_data_service.rb` | Pagination and import transformations |
| `config/initializers/billetto.rb` | Billetto HTTP client |
| `config/initializers/sidekiq.rb` | Redis connection, schedule loading, and startup job |
| `config/initializers/rails_event_store.rb` | Event store configuration |
| `Dockerfile`, `docker-compose.yml` | Web, worker, and Redis container configuration |
| `bin/docker-entrypoint` | Database preparation before the Rails server starts |

## Configuration

Create an untracked `.env` in the project root using your own values:

```dotenv
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/billetto
SECRET_KEY_BASE=replace_with_a_generated_secret
CLERK_PUBLISHABLE_KEY=replace_with_your_publishable_key
CLERK_SECRET_KEY=replace_with_your_secret_key
CLERK_FRONTEND_API_DOMAIN=https://your-instance.accounts.dev
BILLETTO_ACCESS_KEY_ID=replace_with_your_access_key_id
BILLETTO_ACCESS_KEY_SECRET=replace_with_your_access_key_secret
REDIS_URL=redis://127.0.0.1:6379/0
```

Generate a session secret with `ruby -rsecurerandom -e 'puts SecureRandom.hex(64)'`. Set `RAILS_MASTER_KEY` as well if the deployment needs encrypted Rails credentials. Configure the Clerk instance for the local and deployed application URLs.

**Current configuration caveats:**

- Production database configuration currently includes a credential-bearing fallback URL. Supply your own `DATABASE_URL`, remove the fallback, and rotate credentials exposed in source.
- `.env` is excluded from Git and the Docker build context. Compose loads its values through `env_file`; plain Rails commands do not automatically load the file.

## Local development

### Prerequisites

Install Ruby 3.3.3, Bundler, PostgreSQL, and Redis. Native gem installation may also require a compiler, PostgreSQL development libraries, and libvips.

From the repository root:

```sh
bundle install
```

Start PostgreSQL and Redis. The development database defaults to `billetto` on `localhost:5432`, with username and password `postgres`. Adjust `config/database.yml` or supply `DATABASE_URL` for your installation.

Load your environment before running Rails. For a trusted, shell-compatible `.env` file:

```sh
set -a
. ./.env
set +a
export RAILS_ENV=development
bin/rails db:prepare
bin/rails server
```

Quote shell-sensitive values if sourcing the file. Use the appropriate `.env` syntax for your loader; Docker's `--env-file` does not process shell expressions.

In a second terminal, load the same environment and start the worker:

```sh
set -a
. ./.env
set +a
export RAILS_ENV=development
bundle exec sidekiq -C config/sidekiq.yml
```

Open [localhost:3000](http://localhost:3000). Sidekiq startup requests the first import; subsequent imports run every five minutes.

To request an import manually:

```sh
bin/rails runner 'FetchEventJob.perform_later'
```

## Docker Compose setup

Compose runs three services: `web` (Rails through Thruster), `sidekiq` (background worker), and `redis` (persistent queue storage). PostgreSQL must be provided separately; the Compose file does not define a database service.

Create `.env` using the Configuration section above. Set `DATABASE_URL` to a PostgreSQL host reachable from the containers. For PostgreSQL running on the Docker Desktop host, use `host.docker.internal` instead of `localhost`. Compose loads `.env` into the web and worker containers and sets their `REDIS_URL` to `redis://redis:6379/0`.

Build the image and prepare the database before starting the worker:

```sh
docker compose build
docker compose run --rm web ./bin/rails db:prepare
docker compose up -d
```

For subsequent starts, including rebuilding after code changes:

```sh
docker compose up -d --build
```

Open [localhost:3005](http://localhost:3005). The web entrypoint also runs `db:prepare` before starting the Rails server. Sidekiq requests an import when it starts and loads the five-minute schedule.

Check service status and logs:

```sh
docker compose ps
docker compose logs -f web sidekiq
```

Run an import or open the Rails console:

```sh
docker compose exec web ./bin/rails runner 'FetchEventJob.perform_later'
docker compose exec web ./bin/rails console
```

Stop the services and remove their containers:

```sh
docker compose down
```

The named Redis volume is retained by this command. Asset compilation uses dummy build settings; runtime settings come from `.env`.

## Render deployment

The live demo is hosted at [billetto-app-lgv4.onrender.com](https://billetto-app-lgv4.onrender.com/).

For a Docker deployment using this repository:

1. Create a Render web service using the repository's Dockerfile.
2. Configure a reachable PostgreSQL database and the runtime variables listed above in the service environment.
3. Configure Clerk for the deployed URL.
4. Run `./bin/rails db:prepare` against the deployment database before serving traffic, using a release step or an environment with database access.
5. Use `/up` as the health-check path.

The default image command starts Rails through Thruster. Deploy Sidekiq as a separate worker using `bundle exec sidekiq -C config/sidekiq.yml`, and configure both services with the same `DATABASE_URL`, `REDIS_URL`, and application credentials. Redis must be reachable from both services.

## Routes

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/` or `/events` | Paginated event list |
| GET | `/events/:id` | Event details and vote totals |
| POST | `/events/:id/up_vote` | Upvote; requires login |
| POST | `/events/:id/down_vote` | Downvote; requires login |
| GET | `/up` | Rails health check |
| Mounted UI | `/sidekiq` | Sidekiq administration |
| Mounted UI | `/res` | Event Store browser; development only |

The Sidekiq dashboard currently has no application-level authorization constraint; restrict access before exposing it publicly.

## Tests and checks

Configure the test database separately from development and production. If your shell has a development or production `DATABASE_URL`, override it explicitly:

```sh
RAILS_ENV=test DATABASE_URL=postgresql://postgres:postgres@localhost:5432/billetto_test bin/rails db:prepare
RAILS_ENV=test DATABASE_URL=postgresql://postgres:postgres@localhost:5432/billetto_test bundle exec rspec
bundle exec rubocop
bundle exec brakeman --no-pager
```

The RSpec suite is still a scaffold: several examples are pending, factories need alignment with the schema, and the existing request example uses `/events/index` instead of `/events`. The current CI test commands use Rails' Minitest runner and do not execute RSpec.

Other known limitations include application-level vote uniqueness without a composite database constraint, and event-store linking subscribers being registered on a client that is subsequently replaced with a new JSON client.
