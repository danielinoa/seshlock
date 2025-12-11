# frozen_string_literal: true

require "active_support/concern"

module Seshlock
  # Concern for Rails controllers that provides session authentication and management.
  #
  # Include this module in your controller to get access to:
  # - Access token authentication (Bearer token in Authorization header)
  # - Refresh token authentication (from request params)
  # - Login, logout, and token refresh helpers
  #
  # == Example Usage
  #
  #   class SessionsController < ApplicationController
  #     include Seshlock::ControllerMethods
  #
  #     before_action :authenticate_with_seshlock_access_token!, only: [:ping]
  #     before_action :authenticate_with_seshlock_refresh_token!, only: [:logout, :refresh]
  #     rescue_from Seshlock::Error, with: :render_seshlock_error
  #
  #     def login
  #       result = seshlock_login(email: params[:email], password: params[:password])
  #       render json: result, status: :ok
  #     end
  #
  #     def logout
  #       seshlock_logout
  #       head :ok
  #     end
  #
  #     def refresh
  #       result = seshlock_refresh
  #       render json: result, status: :ok
  #     end
  #   end
  #
  # == Error Classes
  #
  # All errors inherit from Seshlock::Error (defined in seshlock/errors.rb):
  #
  # - MissingTokenError      - No token provided (access or refresh)
  # - InvalidTokenError      - Access token is expired or revoked
  # - MalformedTokenError    - Authorization header format is invalid
  # - InvalidGrantError      - Refresh token is expired or revoked
  # - MissingCredentialsError - Email or password not provided
  # - InvalidCredentialsError - Email or password is incorrect
  #
  module ControllerMethods
    extend ActiveSupport::Concern

    included do
      # @return [User, nil] The authenticated user, set after successful authentication.
      attr_reader :current_seshlock_user

      # @return [Seshlock::AccessToken, nil] The validated access token record.
      attr_reader :current_seshlock_access_token

      # @return [Seshlock::RefreshToken, nil] The validated refresh token record.
      attr_reader :current_seshlock_refresh_token
    end

    # -------------------------------------------------------------------------
    # Authentication Methods (use as before_action)
    # -------------------------------------------------------------------------

    # Authenticates the request using a Bearer access token.
    #
    # Extracts the token from the Authorization header, validates it,
    # and sets @current_seshlock_user and @current_seshlock_access_token.
    #
    # @raise [MissingTokenError] if no token is provided
    # @raise [MalformedTokenError] if Authorization header is malformed
    # @raise [InvalidTokenError] if token is expired or revoked
    def authenticate_with_seshlock_access_token!
      raw = extract_bearer_token(request.headers)
      raise Seshlock::MissingTokenError, "Access token not provided" if raw.nil?

      digest = Seshlock::Sessions.digest_token(raw)
      token  = Seshlock::AccessToken.active
                                    .includes(refresh_token: :user)
                                    .find_by(token_digest: digest)

      raise Seshlock::InvalidTokenError, "Token is expired or revoked" unless token

      @current_seshlock_access_token = token
      @current_seshlock_user         = token.refresh_token.user
    end

    # Authenticates the request using a refresh token from params.
    #
    # Expects params[:refresh_token] to contain the raw refresh token.
    # Sets @current_seshlock_refresh_token on success.
    #
    # @raise [MissingTokenError] if no refresh token is provided
    # @raise [InvalidGrantError] if refresh token is expired or revoked
    def authenticate_with_seshlock_refresh_token!
      raw = params[:refresh_token]
      raise Seshlock::MissingTokenError, "Refresh token not provided" if raw.blank?

      digest = Seshlock::Sessions.digest_token(raw)
      token  = Seshlock::RefreshToken.active.find_by(token_digest: digest)

      raise Seshlock::InvalidGrantError, "The refresh token is invalid or has expired" unless token

      @current_seshlock_refresh_token = token
    end

    # -------------------------------------------------------------------------
    # Session Action Helpers
    # -------------------------------------------------------------------------

    # Authenticates a user and issues new tokens.
    #
    # @param email [String] the user's email
    # @param password [String] the user's password
    # @param device [String, nil] optional device identifier for the session
    # @return [Hash] response containing user info and tokens
    # @raise [MissingCredentialsError] if email or password is blank
    # @raise [InvalidCredentialsError] if credentials are invalid
    def seshlock_login(email:, password:, device: nil)
      raise Seshlock::MissingCredentialsError, "Email and password are required" if email.blank? || password.blank?

      user = User.find_by(email: email)
      raise Seshlock::InvalidCredentialsError, "Invalid email or password" unless user&.authenticate(password)

      token_pair = Seshlock::Sessions.issue_tokens_to(user: user, device: device)
      @current_seshlock_user = user

      build_token_response(user: user, token_pair: token_pair)
    end

    # Revokes the current refresh token, ending the session.
    #
    # Call authenticate_with_seshlock_refresh_token! before this method.
    def seshlock_logout
      @current_seshlock_refresh_token&.revoke!
    end

    # Revokes the current refresh token and issues new tokens.
    #
    # Call authenticate_with_seshlock_refresh_token! before this method.
    #
    # @param device [String, nil] optional device identifier for the new session
    # @return [Hash] response containing user info and new tokens
    def seshlock_refresh(device: nil)
      user = @current_seshlock_refresh_token.user
      @current_seshlock_refresh_token.revoke!

      token_pair = Seshlock::Sessions.issue_tokens_to(user: user, device: device)
      @current_seshlock_user = user

      build_token_response(user: user, token_pair: token_pair)
    end

    private

    # Builds the token response hash.
    #
    # Override this method in your controller to customize the response format.
    #
    # @param user [User] the authenticated user
    # @param token_pair [Seshlock::TokenPair] the issued tokens
    # @return [Hash] the response hash
    def build_token_response(user:, token_pair:)
      {
        user: { email: user.email }
      }.merge(token_pair.to_h)
    end

    # Extracts the Bearer token from the Authorization header.
    #
    # @param headers [ActionDispatch::Http::Headers] the request headers
    # @return [String, nil] the token string, or nil if not present
    # @raise [MalformedTokenError] if header exists but is not Bearer format
    def extract_bearer_token(headers)
      auth_header = headers["Authorization"]
      bearer_prefix = "Bearer "

      if auth_header.blank?
        nil
      elsif auth_header.start_with?(bearer_prefix)
        token = auth_header.delete_prefix(bearer_prefix).strip
        token.presence
      else
        raise Seshlock::MalformedTokenError, "Authorization header must start with 'Bearer'"
      end
    end

    # Renders an appropriate error response for Seshlock errors.
    #
    # Use with rescue_from:
    #   rescue_from Seshlock::Error, with: :render_seshlock_error
    #
    # @param exception [Seshlock::Error] the raised exception
    def render_seshlock_error(exception)
      status = case exception
        when Seshlock::MissingCredentialsError, Seshlock::InvalidGrantError
          :bad_request
        when Seshlock::InvalidCredentialsError, Seshlock::MissingTokenError,
            Seshlock::InvalidTokenError, Seshlock::MalformedTokenError
          :unauthorized
        else
          :unauthorized
      end
      render json: { error: exception.message }, status: status
    end
  end
end