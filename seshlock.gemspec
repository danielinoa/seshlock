# frozen_string_literal: true
require_relative "lib/seshlock/version"

Gem::Specification.new do |spec|
  spec.name        = "seshlock"
  spec.version     = Seshlock::VERSION
  spec.summary     = "Session tokens (access + refresh) for Rails apps."
  spec.description = "Seshlock manages access and refresh tokens backed by Active Record, owned by your User model."
  spec.authors     = ["Daniel Inoa"]

  spec.files       = Dir["lib/**/*", "README.md", "LICENSE*", "CHANGELOG.md"].select { |f| File.file?(f) }
  spec.homepage    = "https://github.com/danielinoa/seshlock"
  spec.license     = "MIT"

  spec.metadata = {
    "homepage_uri"    => spec.homepage,
    "source_code_uri" => "https://github.com/danielinoa/seshlock",
    "changelog_uri"   => "https://github.com/danielinoa/seshlock/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "https://github.com/danielinoa/seshlock/issues"
  }

  spec.required_ruby_version = ">= 3.3"

  # Runtime dependency: we rely on Rails (ActiveRecord, ActiveSupport, Railties)
  spec.add_dependency "rails", ">= 8.0"
end