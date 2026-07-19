require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "token-owner@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "generates a prefixed plaintext token on create and stores only its digest" do
    token = @user.api_tokens.create!(name: "CI script")

    assert token.plaintext_token.start_with?("vlg_")
    assert_not_equal token.plaintext_token, token.token_digest
    assert_equal Digest::SHA256.hexdigest(token.plaintext_token), token.token_digest
  end

  test "plaintext token is not persisted" do
    token = @user.api_tokens.create!(name: "CI script")

    assert_nil ApiToken.find(token.id).plaintext_token
  end

  test "requires a name" do
    token = @user.api_tokens.new
    assert_not token.valid?
    assert_includes token.errors[:name], "can't be blank"
  end

  test "authenticate returns the token for a valid plaintext token" do
    token = @user.api_tokens.create!(name: "CI script")

    assert_equal token, ApiToken.authenticate(token.plaintext_token)
  end

  test "authenticate returns nil for unknown or blank tokens" do
    assert_nil ApiToken.authenticate("vlg_not-a-real-token")
    assert_nil ApiToken.authenticate("")
    assert_nil ApiToken.authenticate(nil)
  end

  test "authenticate returns nil for revoked tokens" do
    token = @user.api_tokens.create!(name: "CI script")
    token.revoke!

    assert token.revoked?
    assert_nil ApiToken.authenticate(token.plaintext_token)
  end

  test "touch_last_used records use but throttles repeat writes" do
    token = @user.api_tokens.create!(name: "CI script")
    assert_nil token.last_used_at

    token.touch_last_used
    first_use = token.reload.last_used_at
    assert_not_nil first_use

    token.touch_last_used
    assert_equal first_use, token.reload.last_used_at

    token.update_column(:last_used_at, 2.minutes.ago)
    token.touch_last_used
    assert token.reload.last_used_at > 1.minute.ago
  end

  test "tokens are destroyed with their user" do
    @user.api_tokens.create!(name: "CI script")

    assert_difference "ApiToken.count", -1 do
      @user.destroy!
    end
  end
end
