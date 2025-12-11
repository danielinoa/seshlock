# frozen_string_literal: true

require "test_helper"

class SeshlockErrorsTest < ActiveSupport::TestCase
  def test_error_inherits_from_standard_error
    assert Seshlock::Error < StandardError
  end

  def test_missing_token_error_inherits_from_error
    assert Seshlock::MissingTokenError < Seshlock::Error
  end

  def test_invalid_token_error_inherits_from_error
    assert Seshlock::InvalidTokenError < Seshlock::Error
  end

  def test_malformed_token_error_inherits_from_error
    assert Seshlock::MalformedTokenError < Seshlock::Error
  end

  def test_invalid_grant_error_inherits_from_error
    assert Seshlock::InvalidGrantError < Seshlock::Error
  end

  def test_missing_credentials_error_inherits_from_error
    assert Seshlock::MissingCredentialsError < Seshlock::Error
  end

  def test_invalid_credentials_error_inherits_from_error
    assert Seshlock::InvalidCredentialsError < Seshlock::Error
  end

  def test_errors_can_be_raised_with_message
    error = Seshlock::MissingTokenError.new("Custom message")
    assert_equal "Custom message", error.message
  end

  def test_all_errors_can_be_rescued_by_base_error
    assert_raises(Seshlock::Error) do
      raise Seshlock::MissingTokenError, "test"
    end

    assert_raises(Seshlock::Error) do
      raise Seshlock::InvalidTokenError, "test"
    end

    assert_raises(Seshlock::Error) do
      raise Seshlock::InvalidCredentialsError, "test"
    end
  end
end
