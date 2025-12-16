# frozen_string_literal: true
require "active_record"

class Seshlock::AccessToken < ActiveRecord::Base
  self.table_name = "seshlock_access_tokens"
  # Validations
  validates :token_digest, presence: true, uniqueness: true

  # Associations
  belongs_to :refresh_token, class_name: "Seshlock::RefreshToken", inverse_of: :access_tokens
  has_one :user, through: :refresh_token

  # Scopes
  scope :not_expired, -> { where("expires_at > ?", Time.current) }
  scope :not_revoked, -> { where(revoked_at: nil) }
  scope :active,      -> { not_revoked.not_expired }

  # Status
  def revoked? = revoked_at.present?
  def expired? = Time.current >= expires_at
  def active?  = !revoked? && !expired?

  # Mutations
  def revoke
    update!(revoked_at: Time.current)
  end
end