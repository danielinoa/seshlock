# frozen_string_literal: true

# Defines rails g seshlock:install

require "rails/generators"
require "rails/generators/active_record"

module Seshlock
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)
      desc "Creates Seshlock initializer and core token tables."

      def copy_initializer
        template "initializer.rb", "config/initializers/seshlock.rb"
      end

      def create_migration_file
        migration_template "create_seshlock_core_tables.rb",
                          File.join(db_migrate_path, "create_seshlock_core_tables.rb")
      end

      private

      def db_migrate_path
        "db/migrate"
      end
    end
  end
end