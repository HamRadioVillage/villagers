require "test_helper"

class ApiTokensControllerTest < ActionDispatch::IntegrationTest
  setup do
    @village = Village.create!(name: "Test Village", setup_complete: true)
    @user = create_confirmed_user(email: "owner@example.com")
    @other_user = create_confirmed_user(email: "other@example.com")
  end

  test "index requires authentication" do
    get api_tokens_url
    assert_redirected_to new_user_session_path
  end

  test "index lists the current user's tokens only" do
    @user.api_tokens.create!(name: "My CI token")
    @other_user.api_tokens.create!(name: "Not my token")

    sign_in @user
    get api_tokens_url
    assert_response :success
    assert_match "My CI token", response.body
    assert_no_match "Not my token", response.body
  end

  test "create generates a token and shows the plaintext once" do
    sign_in @user
    assert_difference "@user.api_tokens.count" do
      post api_tokens_url, params: { api_token: { name: "New token" } }
    end
    assert_redirected_to api_tokens_path
    follow_redirect!
    assert_match ApiToken::TOKEN_PREFIX, response.body

    # Plaintext is gone on the next request
    get api_tokens_url
    assert_no_match ApiToken::TOKEN_PREFIX + @user.api_tokens.last.token_digest.first(4), response.body
  end

  test "create with a blank name shows an error" do
    sign_in @user
    assert_no_difference "ApiToken.count" do
      post api_tokens_url, params: { api_token: { name: "" } }
    end
    assert_redirected_to api_tokens_path
  end

  test "destroy revokes the token" do
    token = @user.api_tokens.create!(name: "Old token")
    sign_in @user

    assert_no_difference "ApiToken.count" do
      delete api_token_url(token)
    end
    assert token.reload.revoked?
  end

  test "cannot revoke another user's token" do
    token = @other_user.api_tokens.create!(name: "Not mine")
    sign_in @user

    delete api_token_url(token)
    assert_response :not_found
    assert_not token.reload.revoked?
  end
end
