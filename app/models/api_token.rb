# Personal access token for the JSON API. The plaintext token is generated
# once on create (readable via #plaintext_token until the object is discarded);
# only its SHA-256 digest is stored, so a database leak doesn't leak tokens.
class ApiToken < ApplicationRecord
  TOKEN_PREFIX = "vlg_".freeze

  belongs_to :user

  validates :name, presence: true
  validates :token_digest, presence: true, uniqueness: true

  before_validation :generate_token, on: :create

  scope :active, -> { where(revoked_at: nil) }

  attr_reader :plaintext_token

  def self.digest(plaintext)
    Digest::SHA256.hexdigest(plaintext)
  end

  def self.authenticate(plaintext)
    return nil if plaintext.blank?

    active.find_by(token_digest: digest(plaintext))
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def revoked?
    revoked_at.present?
  end

  # Throttled to one write per minute so authenticated API traffic doesn't
  # turn every read request into a database write.
  def touch_last_used
    return if last_used_at && last_used_at > 1.minute.ago

    update_column(:last_used_at, Time.current)
  end

  private

  def generate_token
    return if token_digest.present?

    @plaintext_token = TOKEN_PREFIX + SecureRandom.base58(32)
    self.token_digest = self.class.digest(@plaintext_token)
  end
end
