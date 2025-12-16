# frozen_string_literal: true

require "test_helper"

class SeshlockAccessTokenTest < SeshlockTestCase
  def setup
    super
    @user = create_user
    @raw_refresh = create_refresh_token(user: @user)
    @refresh_token = Seshlock::RefreshToken.find_by(token_digest: Seshlock::Sessions.digest_token(@raw_refresh))
  end

  # --- Validations ---

  def test_requires_token_digest
    token = Seshlock::AccessToken.new(
      refresh_token: @refresh_token,
      expires_at: 15.minutes.from_now
    )
    assert_not token.valid?
    assert_includes token.errors[:token_digest], "can't be blank"
  end

  def test_requires_unique_token_digest
    digest = "sha256:unique_access_digest"
    Seshlock::AccessToken.create!(
      refresh_token: @refresh_token,
      token_digest: digest,
      expires_at: 15.minutes.from_now
    )

    duplicate = Seshlock::AccessToken.new(
      refresh_token: @refresh_token,
      token_digest: digest,
      expires_at: 15.minutes.from_now
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:token_digest], "has already been taken"
  end

  # --- Status Methods ---

  def test_revoked_returns_true_when_revoked_at_present
    raw_token = create_access_token(refresh_token: @refresh_token, revoked_at: Time.current)
    token = Seshlock::AccessToken.find_by(token_digest: Seshlock::Sessions.digest_token(raw_token))
    assert token.revoked?
  end

  def test_revoked_returns_false_when_revoked_at_nil
    raw_token = create_access_token(refresh_token: @refresh_token)
    token = Seshlock::AccessToken.find_by(token_digest: Seshlock::Sessions.digest_token(raw_token))
    assert_not token.revoked?
  end

  def test_expired_returns_true_when_expires_at_in_past
    raw_token = create_access_token(refresh_token: @refresh_token, expires_at: 1.minute.ago)
    token = Seshlock::AccessToken.find_by(token_digest: Seshlock::Sessions.digest_token(raw_token))
    assert token.expired?
  end

  def test_expired_returns_false_when_expires_at_in_future
    raw_token = create_access_token(refresh_token: @refresh_token, expires_at: 15.minutes.from_now)
    token = Seshlock::AccessToken.find_by(token_digest: Seshlock::Sessions.digest_token(raw_token))
    assert_not token.expired?
  end

  def test_active_returns_true_when_not_revoked_and_not_expired
    raw_token = create_access_token(refresh_token: @refresh_token, expires_at: 15.minutes.from_now)
    token = Seshlock::AccessToken.find_by(token_digest: Seshlock::Sessions.digest_token(raw_token))
    assert token.active?
  end

  def test_active_returns_false_when_revoked
    raw_token = create_access_token(refresh_token: @refresh_token, revoked_at: Time.current)
    token = Seshlock::AccessToken.find_by(token_digest: Seshlock::Sessions.digest_token(raw_token))
    assert_not token.active?
  end

  def test_active_returns_false_when_expired
    raw_token = create_access_token(refresh_token: @refresh_token, expires_at: 1.minute.ago)
    token = Seshlock::AccessToken.find_by(token_digest: Seshlock::Sessions.digest_token(raw_token))
    assert_not token.active?
  end

  # --- Scopes ---

  def test_active_scope_excludes_revoked_tokens
    create_access_token(refresh_token: @refresh_token, revoked_at: Time.current)
    create_access_token(refresh_token: @refresh_token) # active

    assert_equal 1, Seshlock::AccessToken.active.count
  end

  def test_active_scope_excludes_expired_tokens
    create_access_token(refresh_token: @refresh_token, expires_at: 1.minute.ago)
    create_access_token(refresh_token: @refresh_token) # active

    assert_equal 1, Seshlock::AccessToken.active.count
  end

  def test_not_revoked_scope
    create_access_token(refresh_token: @refresh_token, revoked_at: Time.current)
    create_access_token(refresh_token: @refresh_token)

    assert_equal 1, Seshlock::AccessToken.not_revoked.count
  end

  def test_not_expired_scope
    create_access_token(refresh_token: @refresh_token, expires_at: 1.minute.ago)
    create_access_token(refresh_token: @refresh_token)

    assert_equal 1, Seshlock::AccessToken.not_expired.count
  end

  # --- Associations ---

  def test_belongs_to_refresh_token
    raw_token = create_access_token(refresh_token: @refresh_token)
    token = Seshlock::AccessToken.find_by(token_digest: Seshlock::Sessions.digest_token(raw_token))
    
    assert_equal @refresh_token, token.refresh_token
  end

  def test_has_one_user_through_refresh_token
    raw_token = create_access_token(refresh_token: @refresh_token)
    token = Seshlock::AccessToken.find_by(token_digest: Seshlock::Sessions.digest_token(raw_token))

    assert_equal @user, token.user
  end

  def test_user_is_same_as_refresh_token_user
    raw_token = create_access_token(refresh_token: @refresh_token)
    token = Seshlock::AccessToken.find_by(token_digest: Seshlock::Sessions.digest_token(raw_token))

    assert_equal token.refresh_token.user, token.user
  end
end