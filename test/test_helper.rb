# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "seshlock"
require "minitest/autorun"
require "active_record"
require "active_support"
require "active_support/test_case"
require "bcrypt"

# Minimal in-memory DB setup for tests
ActiveRecord::Base.establish_connection(
  adapter:  "sqlite3",
  database: ":memory:"
)

# Create test schema
ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :email, null: false
    t.string :password_digest, null: false
    t.timestamps null: false
  end

  create_table :seshlock_refresh_tokens, force: true do |t|
    t.string     :token_digest,      null: false
    t.datetime   :expires_at,        null: false
    t.datetime   :revoked_at
    t.string     :device_identifier
    t.references :user,              null: false
    t.timestamps null: false
  end

  add_index :seshlock_refresh_tokens, :token_digest, unique: true

  create_table :seshlock_access_tokens, force: true do |t|
    t.string     :token_digest,      null: false
    t.datetime   :expires_at,        null: false
    t.datetime   :revoked_at
    t.references :refresh_token,     null: false
    t.timestamps null: false
  end

  add_index :seshlock_access_tokens, :token_digest, unique: true
end

# Mock User model for testing
class User < ActiveRecord::Base
  has_secure_password
  include Seshlock::UserMethods
end

# Base test class with helpers
class SeshlockTestCase < ActiveSupport::TestCase
  def setup
    # Clean up before each test
    Seshlock::AccessToken.delete_all
    Seshlock::RefreshToken.delete_all
    User.delete_all
  end

  def create_user(email: "test@example.com", password: "password123")
    User.create!(email: email, password: password)
  end

  def create_refresh_token(user:, expires_at: 30.days.from_now, revoked_at: nil, device: nil)
    raw_token = SecureRandom.hex(32)
    Seshlock::RefreshToken.create!(
      user: user,
      token_digest: Seshlock::Sessions.digest_token(raw_token),
      expires_at: expires_at,
      revoked_at: revoked_at,
      device_identifier: device
    )
    raw_token
  end

  def create_access_token(refresh_token:, expires_at: 15.minutes.from_now, revoked_at: nil)
    raw_token = SecureRandom.hex(32)
    Seshlock::AccessToken.create!(
      refresh_token: refresh_token,
      token_digest: Seshlock::Sessions.digest_token(raw_token),
      expires_at: expires_at,
      revoked_at: revoked_at
    )
    raw_token
  end
end