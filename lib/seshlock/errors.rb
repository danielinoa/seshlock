# frozen_string_literal: true

module Seshlock
  # Base error class for all Seshlock errors.
  class Error < StandardError; end

  # Raised when no token is provided in the request.
  class MissingTokenError < Error; end

  # Raised when the access token is expired or revoked.
  class InvalidTokenError < Error; end

  # Raised when the Authorization header is not in "Bearer <token>" format.
  class MalformedTokenError < Error; end

  # Raised when the refresh token is invalid, expired, or revoked.
  class InvalidGrantError < Error; end

  # Raised when email or password is not provided.
  class MissingCredentialsError < Error; end

  # Raised when email or password is incorrect.
  class InvalidCredentialsError < Error; end
end
