class Village < ApplicationRecord
  has_many :programs, dependent: :destroy
  has_many :qualifications, dependent: :destroy

  validates :name, presence: true
  validates :mailgun_api_key, presence: true, if: :email_enabled?
  validates :mailgun_domain, presence: true, if: :email_enabled?
  validates :mailgun_region, inclusion: { in: %w[us eu] }, allow_blank: true

  def self.setup_complete?
    exists? && first.setup_complete?
  end

  # Email configuration class methods
  def self.email_enabled?
    return false unless exists?

    setup_complete? && first&.email_enabled?
  end

  def self.mailgun_settings
    return {} unless setup_complete?

    village = first
    {
      api_key: village.mailgun_api_key,
      domain: village.mailgun_domain,
      region: village.mailgun_region || "us"
    }
  end

  def self.current
    first
  end
end
