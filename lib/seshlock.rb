# frozen_string_literal: true

require "seshlock/version"
require "seshlock/configuration"
require "seshlock/errors"
require "seshlock/railtie" if defined?(Rails::Railtie)

module Seshlock
  class << self
    # Seshlock.configure do |config|
    #   config.access_token_ttl  = 10.minutes
    #   config.refresh_token_ttl = 14.days
    # end
    def configure
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end
  end
end

# These requires are placed at the bottom to ensure that the Seshlock module and its configuration
# are fully defined before loading components that depend on them. This avoids load order issues
# and ensures all references to Seshlock and its configuration are available.

# Load core models & API
require "seshlock/refresh_token"
require "seshlock/access_token"
require "seshlock/sessions"
require "seshlock/user_methods"
require "seshlock/controller_methods"