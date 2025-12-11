# frozen_string_literal: true
require "active_record"

class Seshlock::RefreshToken < ActiveRecord::Base
  # Validations
  validates :token_digest, uniqueness: true, presence: true

  # Associations
  belongs_to :user, class_name: "User", inverse_of: :seshlock_refresh_tokens
  has_many :access_tokens, dependent: :destroy, inverse_of: :refresh_token

  # Scopes
  scope :not_expired, -> { where("expires_at > ?", Time.current) }
  scope :not_revoked, -> { where(revoked_at: nil) }
  scope :active,      -> { not_revoked.not_expired }

  # Status
  def revoked? = revoked_at.present?
  def expired? = Time.current >= expires_at
  def active? = !revoked? && !expired?
  
  # Mutations
  def revoke!
    # The associated access_tokens are destroyed in the database as part of the revocation.
    # The changes are not reflected for the in-memory object until `reload` is invoked.
    transaction do
      access_tokens.update_all(revoked_at: Time.current)
      update!(revoked_at: Time.current)
    end
  end
end
