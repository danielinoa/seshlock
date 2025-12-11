# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-12-11

### Added

- Initial release
- Access token and refresh token models with SHA-256 hashing
- `Seshlock::Sessions` module for issuing, refreshing, and revoking tokens
- `Seshlock::ControllerMethods` concern with authentication helpers
- `Seshlock::UserMethods` concern for User model integration
- Configurable TTLs for access and refresh tokens
- Rails generator (`rails g seshlock:install`) for migrations and initializer
- Comprehensive error classes for auth failures
- Device identifier support for session tracking
