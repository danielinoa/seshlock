# frozen_string_literal: true

require "active_support/concern"

module Seshlock
  module UserMethods
    extend ActiveSupport::Concern

    included do
      has_many :seshlock_refresh_tokens,
                class_name: "Seshlock::RefreshToken",
                foreign_key: :user_id,
                inverse_of: :user,
                dependent: :destroy

      has_many :seshlock_access_tokens,
                class_name: "Seshlock::AccessToken",
                through: :seshlock_refresh_tokens
    end

    # Convenience helper
    def issue_seshlock_session(device: nil)
      Seshlock::Sessions.issue_tokens_to(user: self, device: device)
    end
  end
end
