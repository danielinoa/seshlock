# frozen_string_literal: true

require "bundler/gem_tasks"  # adds build/install/release tasks

# Default task: run tests
task default: :test

# Simple test runner using minitest
task :test do
  $LOAD_PATH.unshift("lib", "test")
  Dir.glob("test/**/*_test.rb").each { |f| require_relative f }
end