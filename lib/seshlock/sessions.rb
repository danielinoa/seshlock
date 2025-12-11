# frozen_string_literal: true

require "securerandom"
require "digest"

module Seshlock
  # Simple immutable value object returned on initial issue
  TokenPair = Data.define(
    :access_token,
    :access_token_expires_at,
    :refresh_token,
    :refresh_token_expires_at
  ) do
    def to_h
      {
        access_token: access_token,
        access_token_expires_at: access_token_expires_at,
        refresh_token: refresh_token,
        refresh_token_expires_at: refresh_token_expires_at
      }
    end
  end

  module Sessions
    module_function

    # Issue a new refresh + access token pair for a user.
    #
    # Returns a TokenPair with **raw** token strings and their expirations.
    # Only digests are stored in the DB.
    def issue_tokens_to(user:, device: nil)
      now = Time.current

      refresh_expires_at = now + Seshlock.configuration.refresh_token_ttl
      access_expires_at  = now + Seshlock.configuration.access_token_ttl

      # Refresh Token with retry on collision
      begin
        raw_refresh_token = generate_random_token
        refresh_record = RefreshToken.create!(
          user:              user,
          token_digest:      digest_token(raw_refresh_token),
          expires_at:        refresh_expires_at,
          device_identifier: device,
          revoked_at:        nil
        )
      rescue ActiveRecord::RecordNotUnique
        retry
      end

      # Access Token with retry on collision
      begin
        raw_access_token = generate_random_token
        AccessToken.create!(
          refresh_token: refresh_record,
          token_digest:  digest_token(raw_access_token),
          expires_at:    access_expires_at,
          revoked_at:    nil
        )
      rescue ActiveRecord::RecordNotUnique
        retry
      end

      TokenPair.new(
        access_token:              raw_access_token,
        access_token_expires_at:   access_expires_at,
        refresh_token:             raw_refresh_token,
        refresh_token_expires_at:  refresh_expires_at
      )
    end

    # Given a **raw** refresh token string, rotate tokens.
    #
    # Revokes the old refresh token and issues a new token pair.
    # Returns a TokenPair or nil if the refresh token is invalid.
    def refresh(refresh_token:, device: nil)
      return nil if refresh_token.to_s.empty?

      digest = digest_token(refresh_token)
      refresh_record = RefreshToken.active.find_by(token_digest: digest)
      return nil unless refresh_record

      user = refresh_record.user
      refresh_record.revoke!

      issue_tokens_to(user: user, device: device)
    end

    def revoke_refresh_token(raw_refresh_token:)
      digest = digest_token(raw_refresh_token)
      record = RefreshToken.find_by(token_digest: digest)
      record&.revoke!
    end

    # Helpers

    def generate_random_token
      SecureRandom.hex(32) # 64 hex chars = 32 bytes entropy
    end

    def digest_token(raw)
      "sha256:" + Digest::SHA256.hexdigest(raw)
    end
  end
end
