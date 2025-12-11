# rails_gem/lib/generators/seshlock/install/templates/create_seshlock_core_tables.rb
# frozen_string_literal: true

class CreateSeshlockCoreTables < ActiveRecord::Migration[8.0]
  def change
    create_table :seshlock_refresh_tokens do |t|
      t.string     :token_digest,      null: false
      t.datetime   :expires_at,        null: false
      t.datetime   :revoked_at
      t.string     :device_identifier
      t.references :user,              null: false, foreign_key: true

      t.timestamps null: false
    end

    add_index :seshlock_refresh_tokens, :token_digest, unique: true

    create_table :seshlock_access_tokens do |t|
      t.string     :token_digest,      null: false
      t.datetime   :expires_at,        null: false
      t.datetime   :revoked_at
      t.references :refresh_token,     null: false, foreign_key: { to_table: :seshlock_refresh_tokens }

      t.timestamps null: false
    end

    add_index :seshlock_access_tokens, :token_digest, unique: true
  end
end
