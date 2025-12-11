# Seshlock

[![Tests](https://github.com/danielinoa/seshlock/actions/workflows/test.yml/badge.svg)](https://github.com/danielinoa/seshlock/actions/workflows/test.yml)

Session token management for Rails applications. Seshlock provides secure access and refresh token authentication backed by Active Record.

## Features

- **Access + Refresh Token Pattern**: Short-lived access tokens with long-lived refresh tokens
- **Secure by Default**: Tokens are hashed before storage (SHA-256)
- **Device Tracking**: Optional device identifier per session
- **Rails Integration**: Generator for migrations, configurable TTLs, controller helpers

## Requirements

- Ruby 3.3+
- Rails 8.0+

## Installation

Add to your Gemfile:

```ruby
gem "seshlock"
```

Then run:

```bash
bundle install
rails generate seshlock:install
rails db:migrate
```

## Configuration

The generator creates `config/initializers/seshlock.rb`:

```ruby
Seshlock.configure do |config|
  config.access_token_ttl  = 15.minutes
  config.refresh_token_ttl = 30.days
end
```

## Setup

### 1. Include UserMethods in your User model

```ruby
class User < ApplicationRecord
  include Seshlock::UserMethods
  has_secure_password
end
```

### 2. Create a SessionsController

```ruby
class SessionsController < ApplicationController
  include Seshlock::ControllerMethods

  # Skip any existing auth for login
  skip_before_action :authenticate!, only: [:login]

  # Protect these endpoints with the appropriate token type
  before_action :authenticate_with_seshlock_access_token!, only: [:ping]
  before_action :authenticate_with_seshlock_refresh_token!, only: [:logout, :refresh]

  # Handle Seshlock errors gracefully
  rescue_from Seshlock::Error, with: :render_seshlock_error

  # POST /login
  def login
    result = seshlock_login(
      email: params[:email],
      password: params[:password],
      device: params[:device]
    )
    render json: result, status: :ok
  end

  # POST /logout
  def logout
    seshlock_logout
    head :ok
  end

  # POST /refresh
  def refresh
    result = seshlock_refresh(device: params[:device])
    render json: result, status: :ok
  end

  # GET /ping (protected endpoint example)
  def ping
    render json: { message: "pong", user: current_seshlock_user.email }
  end
end
```

### 3. Add routes

```ruby
Rails.application.routes.draw do
  post "login",   to: "sessions#login"
  post "logout",  to: "sessions#logout"
  post "refresh", to: "sessions#refresh"
  get  "ping",    to: "sessions#ping"
end
```

## API Reference

### Controller Methods

When you include `Seshlock::ControllerMethods`, you get:

#### Authentication (use as `before_action`)

- `authenticate_with_seshlock_access_token!` - Validates Bearer token from Authorization header
- `authenticate_with_seshlock_refresh_token!` - Validates refresh token from `params[:refresh_token]`

#### Instance Variables (set after authentication)

- `@current_seshlock_user` - The authenticated User record
- `@current_seshlock_access_token` - The AccessToken record
- `@current_seshlock_refresh_token` - The RefreshToken record

#### Action Helpers

- `seshlock_login(email:, password:, device: nil)` - Authenticates and issues tokens
- `seshlock_logout` - Revokes the current refresh token
- `seshlock_refresh(device: nil)` - Rotates tokens (revokes old, issues new)

### Sessions Module

For programmatic access:

```ruby
# Issue new tokens
token_pair = Seshlock::Sessions.issue_tokens_to(user: user, device: "iPhone")
token_pair.access_token              # => "abc123..."
token_pair.access_token_expires_at   # => Time
token_pair.refresh_token             # => "def456..."
token_pair.refresh_token_expires_at  # => Time

# Refresh (returns [access_token, expires_at] or nil)
result = Seshlock::Sessions.refresh(refresh_token: raw_token)

# Revoke
Seshlock::Sessions.revoke_refresh_token(raw_refresh_token: token)
```

### User Methods

The `Seshlock::UserMethods` concern adds:

```ruby
user.seshlock_refresh_tokens  # => has_many association
user.seshlock_access_tokens   # => has_many through refresh_tokens
user.issue_seshlock_session(device: nil)  # => TokenPair
```

## Error Handling

All errors inherit from `Seshlock::Error`:

| Error | When Raised | Suggested HTTP Status |
|-------|-------------|----------------------|
| `MissingTokenError` | No token provided | 401 Unauthorized |
| `InvalidTokenError` | Access token expired/revoked | 401 Unauthorized |
| `MalformedTokenError` | Authorization header malformed | 401 Unauthorized |
| `InvalidGrantError` | Refresh token expired/revoked | 400 Bad Request |
| `MissingCredentialsError` | Email/password not provided | 400 Bad Request |
| `InvalidCredentialsError` | Wrong email/password | 401 Unauthorized |

Use `render_seshlock_error` helper or implement your own:

```ruby
rescue_from Seshlock::Error, with: :render_seshlock_error
```

## Client Usage

### Login

```bash
curl -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "secret"}'
```

Response:

```json
{
  "user": { "email": "user@example.com" },
  "access_token": "abc123...",
  "access_token_expires_at": "2024-01-01T12:15:00Z",
  "refresh_token": "def456...",
  "refresh_token_expires_at": "2024-01-31T12:00:00Z"
}
```

### Authenticated Request

```bash
curl http://localhost:3000/ping \
  -H "Authorization: Bearer abc123..."
```

### Refresh Tokens

```bash
curl -X POST http://localhost:3000/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token": "def456..."}'
```

## License

MIT License. See [LICENSE](LICENSE) for details.
