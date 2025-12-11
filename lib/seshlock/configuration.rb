# frozen_string_literal: true

require "active_support/core_ext/numeric/time"

module Seshlock
  class Configuration
    attr_accessor :access_token_ttl, :refresh_token_ttl

    def initialize
      # TTLs for access/refresh tokens
      @access_token_ttl  = 15.minutes
      @refresh_token_ttl = 30.days
    end
  end
end