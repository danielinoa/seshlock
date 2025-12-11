# frozen_string_literal: true

require "test_helper"
require "rails/generators"
require "rails/generators/test_case"
require "generators/seshlock/install/install_generator"

class SeshlockInstallGeneratorTest < Rails::Generators::TestCase
  tests Seshlock::Generators::InstallGenerator
  destination File.expand_path("../tmp/generator_test", __dir__)

  setup do
    prepare_destination
  end

  test "creates initializer file" do
    run_generator

    assert_file "config/initializers/seshlock.rb" do |content|
      assert_match(/Seshlock\.configure/, content)
      assert_match(/config\.access_token_ttl/, content)
      assert_match(/config\.refresh_token_ttl/, content)
      assert_match(/15\.minutes/, content)
      assert_match(/30\.days/, content)
    end
  end

  test "creates migration file" do
    run_generator

    assert_migration "db/migrate/create_seshlock_core_tables.rb" do |content|
      # Check migration class
      assert_match(/class CreateSeshlockCoreTables < ActiveRecord::Migration/, content)

      # Check refresh_tokens table
      assert_match(/create_table :seshlock_refresh_tokens/, content)
      assert_match(/t\.string\s+:token_digest/, content)
      assert_match(/t\.datetime\s+:expires_at/, content)
      assert_match(/t\.datetime\s+:revoked_at/, content)
      assert_match(/t\.string\s+:device_identifier/, content)
      assert_match(/t\.references\s+:user/, content)

      # Check access_tokens table
      assert_match(/create_table :seshlock_access_tokens/, content)
      assert_match(/t\.references\s+:refresh_token/, content)

      # Check indexes
      assert_match(/add_index :seshlock_refresh_tokens, :token_digest, unique: true/, content)
      assert_match(/add_index :seshlock_access_tokens, :token_digest, unique: true/, content)
    end
  end

  test "migration has proper timestamp" do
    run_generator

    migration_file = Dir["#{destination_root}/db/migrate/*_create_seshlock_core_tables.rb"].first
    assert migration_file, "Migration file should exist"

    # Extract timestamp from filename (format: YYYYMMDDHHMMSS)
    timestamp = File.basename(migration_file).match(/^(\d{14})_/)[1]
    assert_match(/^\d{14}$/, timestamp, "Migration should have 14-digit timestamp")
  end

  test "generator is idempotent for initializer" do
    run_generator
    initial_content = File.read(File.join(destination_root, "config/initializers/seshlock.rb"))

    run_generator
    final_content = File.read(File.join(destination_root, "config/initializers/seshlock.rb"))

    assert_equal initial_content, final_content, "Running generator twice should not change initializer"
  end
end
