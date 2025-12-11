# frozen_string_literal: true

# What gets written into config/initializers/seshlock.rb. in a Rails app.

Seshlock.configure do |config|
  # Token lifetimes
  config.access_token_ttl  = 15.minutes
  config.refresh_token_ttl = 30.days
end