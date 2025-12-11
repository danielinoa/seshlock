# frozen_string_literal: true

require "test_helper"

class SeshlockUserMethodsTest < SeshlockTestCase
  def setup
    super
    @user = create_user
  end

  # --- Associations ---

  def test_user_has_many_seshlock_refresh_tokens
    assert_respond_to @user, :seshlock_refresh_tokens
  end

  def test_user_has_many_seshlock_access_tokens
    assert_respond_to @user, :seshlock_access_tokens
  end

  def test_refresh_tokens_are_destroyed_when_user_is_destroyed
    Seshlock::Sessions.issue_tokens_to(user: @user)
    
    assert_equal 1, Seshlock::RefreshToken.count
    @user.destroy
    assert_equal 0, Seshlock::RefreshToken.count
  end

  # --- issue_seshlock_session ---

  def test_issue_seshlock_session_returns_token_pair
    result = @user.issue_seshlock_session

    assert_instance_of Seshlock::TokenPair, result
    assert_not_nil result.access_token
    assert_not_nil result.refresh_token
  end

  def test_issue_seshlock_session_with_device
    result = @user.issue_seshlock_session(device: "iPhone 15")
    refresh_digest = Seshlock::Sessions.digest_token(result.refresh_token)
    refresh_token = Seshlock::RefreshToken.find_by(token_digest: refresh_digest)

    assert_equal "iPhone 15", refresh_token.device_identifier
  end

  def test_issue_seshlock_session_creates_tokens_for_user
    result = @user.issue_seshlock_session
    refresh_digest = Seshlock::Sessions.digest_token(result.refresh_token)
    refresh_token = Seshlock::RefreshToken.find_by(token_digest: refresh_digest)

    assert_equal @user, refresh_token.user
  end
end
