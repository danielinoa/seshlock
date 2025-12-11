# frozen_string_literal: true

require "test_helper"

class SeshlockSessionsTest < SeshlockTestCase
  def setup
    super
    @user = create_user
  end

  # --- issue_tokens_to ---

  def test_issue_tokens_to_returns_token_pair
    result = Seshlock::Sessions.issue_tokens_to(user: @user)

    assert_instance_of Seshlock::TokenPair, result
    assert_not_nil result.access_token
    assert_not_nil result.access_token_expires_at
    assert_not_nil result.refresh_token
    assert_not_nil result.refresh_token_expires_at
  end

  def test_issue_tokens_to_creates_refresh_token_record
    assert_difference "Seshlock::RefreshToken.count", 1 do
      Seshlock::Sessions.issue_tokens_to(user: @user)
    end
  end

  def test_issue_tokens_to_creates_access_token_record
    assert_difference "Seshlock::AccessToken.count", 1 do
      Seshlock::Sessions.issue_tokens_to(user: @user)
    end
  end

  def test_issue_tokens_to_stores_digested_tokens
    result = Seshlock::Sessions.issue_tokens_to(user: @user)

    refresh_digest = Seshlock::Sessions.digest_token(result.refresh_token)
    access_digest = Seshlock::Sessions.digest_token(result.access_token)

    assert Seshlock::RefreshToken.exists?(token_digest: refresh_digest)
    assert Seshlock::AccessToken.exists?(token_digest: access_digest)
  end

  def test_issue_tokens_to_sets_correct_expiration_times
    result = Seshlock::Sessions.issue_tokens_to(user: @user)

    # Access token should expire according to configuration (default 15 minutes)
    assert_in_delta Seshlock.configuration.access_token_ttl.from_now,
                    result.access_token_expires_at,
                    1.second

    # Refresh token should expire according to configuration (default 30 days)
    assert_in_delta Seshlock.configuration.refresh_token_ttl.from_now,
                    result.refresh_token_expires_at,
                    1.second
  end

  def test_issue_tokens_to_with_device_identifier
    result = Seshlock::Sessions.issue_tokens_to(user: @user, device: "iPhone 15")
    refresh_digest = Seshlock::Sessions.digest_token(result.refresh_token)
    refresh_token = Seshlock::RefreshToken.find_by(token_digest: refresh_digest)

    assert_equal "iPhone 15", refresh_token.device_identifier
  end

  def test_issue_tokens_to_associates_tokens_with_user
    result = Seshlock::Sessions.issue_tokens_to(user: @user)
    refresh_digest = Seshlock::Sessions.digest_token(result.refresh_token)
    refresh_token = Seshlock::RefreshToken.find_by(token_digest: refresh_digest)

    assert_equal @user, refresh_token.user
  end

  # --- refresh ---

  def test_refresh_returns_new_access_token
    token_pair = Seshlock::Sessions.issue_tokens_to(user: @user)
    result = Seshlock::Sessions.refresh(refresh_token: token_pair.refresh_token)

    assert_not_nil result
    assert_equal 2, result.length
    assert_kind_of String, result[0]  # new access token
    assert_kind_of Time, result[1]    # expires_at
  end

  def test_refresh_creates_new_access_token_record
    token_pair = Seshlock::Sessions.issue_tokens_to(user: @user)

    assert_difference "Seshlock::AccessToken.count", 1 do
      Seshlock::Sessions.refresh(refresh_token: token_pair.refresh_token)
    end
  end

  def test_refresh_returns_nil_for_empty_token
    assert_nil Seshlock::Sessions.refresh(refresh_token: "")
    assert_nil Seshlock::Sessions.refresh(refresh_token: nil)
  end

  def test_refresh_returns_nil_for_invalid_token
    result = Seshlock::Sessions.refresh(refresh_token: "invalid_token")
    assert_nil result
  end

  def test_refresh_returns_nil_for_revoked_token
    token_pair = Seshlock::Sessions.issue_tokens_to(user: @user)
    Seshlock::Sessions.revoke_refresh_token(raw_refresh_token: token_pair.refresh_token)

    result = Seshlock::Sessions.refresh(refresh_token: token_pair.refresh_token)
    assert_nil result
  end

  def test_refresh_returns_nil_for_expired_token
    raw_token = create_refresh_token(user: @user, expires_at: 1.day.ago)
    result = Seshlock::Sessions.refresh(refresh_token: raw_token)
    assert_nil result
  end

  # --- revoke_refresh_token ---

  def test_revoke_refresh_token_revokes_token
    token_pair = Seshlock::Sessions.issue_tokens_to(user: @user)
    refresh_digest = Seshlock::Sessions.digest_token(token_pair.refresh_token)
    
    Seshlock::Sessions.revoke_refresh_token(raw_refresh_token: token_pair.refresh_token)

    refresh_token = Seshlock::RefreshToken.find_by(token_digest: refresh_digest)
    assert refresh_token.revoked?
  end

  def test_revoke_refresh_token_revokes_associated_access_tokens
    token_pair = Seshlock::Sessions.issue_tokens_to(user: @user)
    access_digest = Seshlock::Sessions.digest_token(token_pair.access_token)
    
    Seshlock::Sessions.revoke_refresh_token(raw_refresh_token: token_pair.refresh_token)

    access_token = Seshlock::AccessToken.find_by(token_digest: access_digest)
    assert access_token.revoked?
  end

  def test_revoke_refresh_token_handles_invalid_token
    # Should not raise an error
    assert_nothing_raised do
      Seshlock::Sessions.revoke_refresh_token(raw_refresh_token: "invalid_token")
    end
  end

  # --- Helper Methods ---

  def test_generate_random_token_returns_64_char_hex_string
    token = Seshlock::Sessions.generate_random_token
    
    assert_equal 64, token.length
    assert_match(/\A[a-f0-9]+\z/, token)
  end

  def test_generate_random_token_returns_unique_values
    tokens = 10.times.map { Seshlock::Sessions.generate_random_token }
    assert_equal tokens.uniq.length, tokens.length
  end

  def test_digest_token_returns_sha256_prefixed_hash
    raw = "test_token"
    digest = Seshlock::Sessions.digest_token(raw)

    assert digest.start_with?("sha256:")
    assert_equal 71, digest.length  # "sha256:" (7) + 64-char hex
  end

  def test_digest_token_returns_consistent_results
    raw = "test_token"
    digest1 = Seshlock::Sessions.digest_token(raw)
    digest2 = Seshlock::Sessions.digest_token(raw)

    assert_equal digest1, digest2
  end

  # --- TokenPair ---

  def test_token_pair_to_h
    token_pair = Seshlock::Sessions.issue_tokens_to(user: @user)
    hash = token_pair.to_h

    assert_equal token_pair.access_token, hash[:access_token]
    assert_equal token_pair.access_token_expires_at, hash[:access_token_expires_at]
    assert_equal token_pair.refresh_token, hash[:refresh_token]
    assert_equal token_pair.refresh_token_expires_at, hash[:refresh_token_expires_at]
  end
end