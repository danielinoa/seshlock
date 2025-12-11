# frozen_string_literal: true

require "test_helper"

class SeshlockRefreshTokenTest < SeshlockTestCase
  def setup
    super
    @user = create_user
  end

  # --- Validations ---

  def test_requires_token_digest
    token = Seshlock::RefreshToken.new(
      user: @user,
      expires_at: 30.days.from_now
    )
    assert_not token.valid?
    assert_includes token.errors[:token_digest], "can't be blank"
  end

  def test_requires_unique_token_digest
    digest = "sha256:unique_digest"
    Seshlock::RefreshToken.create!(
      user: @user,
      token_digest: digest,
      expires_at: 30.days.from_now
    )

    duplicate = Seshlock::RefreshToken.new(
      user: @user,
      token_digest: digest,
      expires_at: 30.days.from_now
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:token_digest], "has already been taken"
  end

  # --- Status Methods ---

  def test_revoked_returns_true_when_revoked_at_present
    raw_token = create_refresh_token(user: @user, revoked_at: Time.current)
    token = Seshlock::RefreshToken.find_by(token_digest: Seshlock::Sessions.digest_token(raw_token))
    assert token.revoked?
  end

  def test_revoked_returns_false_when_revoked_at_nil
    raw_token = create_refresh_token(user: @user)
    token = Seshlock::RefreshToken.find_by(token_digest: Seshlock::Sessions.digest_token(raw_token))
    assert_not token.revoked?
  end

  def test_expired_returns_true_when_expires_at_in_past
    raw_token = create_refresh_token(user: @user, expires_at: 1.day.ago)
    token = Seshlock::RefreshToken.find_by(token_digest: Seshlock::Sessions.digest_token(raw_token))
    assert token.expired?
  end

  def test_expired_returns_false_when_expires_at_in_future
    raw_token = create_refresh_token(user: @user, expires_at: 1.day.from_now)
    token = Seshlock::RefreshToken.find_by(token_digest: Seshlock::Sessions.digest_token(raw_token))
    assert_not token.expired?
  end

  def test_active_returns_true_when_not_revoked_and_not_expired
    raw_token = create_refresh_token(user: @user, expires_at: 1.day.from_now)
    token = Seshlock::RefreshToken.find_by(token_digest: Seshlock::Sessions.digest_token(raw_token))
    assert token.active?
  end

  def test_active_returns_false_when_revoked
    raw_token = create_refresh_token(user: @user, revoked_at: Time.current)
    token = Seshlock::RefreshToken.find_by(token_digest: Seshlock::Sessions.digest_token(raw_token))
    assert_not token.active?
  end

  def test_active_returns_false_when_expired
    raw_token = create_refresh_token(user: @user, expires_at: 1.day.ago)
    token = Seshlock::RefreshToken.find_by(token_digest: Seshlock::Sessions.digest_token(raw_token))
    assert_not token.active?
  end

  # --- Scopes ---

  def test_active_scope_excludes_revoked_tokens
    create_refresh_token(user: @user, revoked_at: Time.current)
    create_refresh_token(user: @user) # active

    assert_equal 1, Seshlock::RefreshToken.active.count
  end

  def test_active_scope_excludes_expired_tokens
    create_refresh_token(user: @user, expires_at: 1.day.ago)
    create_refresh_token(user: @user) # active

    assert_equal 1, Seshlock::RefreshToken.active.count
  end

  def test_not_revoked_scope
    create_refresh_token(user: @user, revoked_at: Time.current)
    create_refresh_token(user: @user)

    assert_equal 1, Seshlock::RefreshToken.not_revoked.count
  end

  def test_not_expired_scope
    create_refresh_token(user: @user, expires_at: 1.day.ago)
    create_refresh_token(user: @user)

    assert_equal 1, Seshlock::RefreshToken.not_expired.count
  end

  # --- Revoke ---

  def test_revoke_sets_revoked_at
    raw_token = create_refresh_token(user: @user)
    token = Seshlock::RefreshToken.find_by(token_digest: Seshlock::Sessions.digest_token(raw_token))

    assert_nil token.revoked_at
    token.revoke!
    token.reload

    assert_not_nil token.revoked_at
    assert token.revoked?
  end

  def test_revoke_revokes_associated_access_tokens
    raw_refresh = create_refresh_token(user: @user)
    refresh_token = Seshlock::RefreshToken.find_by(token_digest: Seshlock::Sessions.digest_token(raw_refresh))
    
    raw_access = create_access_token(refresh_token: refresh_token)
    access_token = Seshlock::AccessToken.find_by(token_digest: Seshlock::Sessions.digest_token(raw_access))

    assert_nil access_token.revoked_at
    refresh_token.revoke!
    access_token.reload

    assert_not_nil access_token.revoked_at
    assert access_token.revoked?
  end

  # --- Associations ---

  def test_belongs_to_user
    raw_token = create_refresh_token(user: @user)
    token = Seshlock::RefreshToken.find_by(token_digest: Seshlock::Sessions.digest_token(raw_token))
    
    assert_equal @user, token.user
  end

  def test_has_many_access_tokens
    raw_refresh = create_refresh_token(user: @user)
    refresh_token = Seshlock::RefreshToken.find_by(token_digest: Seshlock::Sessions.digest_token(raw_refresh))
    
    create_access_token(refresh_token: refresh_token)
    create_access_token(refresh_token: refresh_token)

    assert_equal 2, refresh_token.access_tokens.count
  end
end