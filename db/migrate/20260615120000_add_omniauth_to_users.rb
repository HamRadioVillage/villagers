class AddOmniauthToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :provider, :string
    add_column :users, :uid, :string

    # A given identity (provider + uid) maps to at most one user. Both columns
    # are null for password-only accounts, so the index is non-unique-friendly
    # by being scoped to rows where provider is present is not portable across
    # adapters; instead we keep a plain unique composite index. MySQL/MariaDB and
    # Postgres both treat multiple NULLs as distinct, so password users coexist.
    add_index :users, [ :provider, :uid ], unique: true
  end
end
