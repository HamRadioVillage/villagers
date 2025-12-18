class AddEmailSettingsToVillages < ActiveRecord::Migration[8.1]
  def change
    add_column :villages, :email_enabled, :boolean, default: false, null: false
    add_column :villages, :mailgun_api_key, :string
    add_column :villages, :mailgun_domain, :string
    add_column :villages, :mailgun_region, :string, default: "us"
  end
end
