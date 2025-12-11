# frozen_string_literal: true

require "test_helper"

class SeshlockConfigurationTest < ActiveSupport::TestCase
  def setup
    # Reset configuration before each test
    Seshlock.instance_variable_set(:@configuration, nil)
  end

  def teardown
    # Reset configuration after each test
    Seshlock.instance_variable_set(:@configuration, nil)
  end

  def test_default_access_token_ttl
    assert_equal 15.minutes, Seshlock.configuration.access_token_ttl
  end

  def test_default_refresh_token_ttl
    assert_equal 30.days, Seshlock.configuration.refresh_token_ttl
  end

  def test_configure_access_token_ttl
    Seshlock.configure do |config|
      config.access_token_ttl = 10.minutes
    end

    assert_equal 10.minutes, Seshlock.configuration.access_token_ttl
  end

  def test_configure_refresh_token_ttl
    Seshlock.configure do |config|
      config.refresh_token_ttl = 7.days
    end

    assert_equal 7.days, Seshlock.configuration.refresh_token_ttl
  end

  def test_configuration_is_memoized
    config1 = Seshlock.configuration
    config2 = Seshlock.configuration

    assert_same config1, config2
  end
end
