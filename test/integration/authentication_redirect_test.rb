require "test_helper"

# Covers issue #180: unauthenticated requests to protected pages must redirect
# to the sign-in page (previously some raised a 500), while the intended public
# pages stay reachable without logging in.
class AuthenticationRedirectTest < ActionDispatch::IntegrationTest
  setup do
    @village = Village.create!(name: "Test Village", setup_complete: true)
    @conference = Conference.create!(
      village: @village, name: "Test Conference",
      start_date: Date.tomorrow, end_date: Date.tomorrow + 2.days
    )
  end

  # --- Protected pages redirect anonymous users to sign-in ---
  test "anonymous access to conferences index redirects to sign-in (was a 500)" do
    get conferences_path
    assert_redirected_to new_user_session_path
  end

  test "anonymous access to a conference redirects to sign-in" do
    get conference_path(@conference)
    assert_redirected_to new_user_session_path
  end

  test "anonymous access to programs redirects to sign-in" do
    get programs_path
    assert_redirected_to new_user_session_path
  end

  test "anonymous access to qualifications redirects to sign-in" do
    get qualifications_path
    assert_redirected_to new_user_session_path
  end

  test "anonymous access to the village page redirects to sign-in" do
    get village_path
    assert_redirected_to new_user_session_path
  end

  test "anonymous access to the schedule redirects to sign-in" do
    get conference_schedule_path(@conference)
    assert_redirected_to new_user_session_path
  end

  # --- Public pages remain reachable without authentication ---
  test "home page is public" do
    get root_path
    assert_response :success
  end

  test "health endpoint is public" do
    get health_path
    assert_response :success
  end

  test "sign-in page is public" do
    get new_user_session_path
    assert_response :success
  end

  test "sign-up page is public" do
    get new_user_registration_path
    assert_response :success
  end

  test "password reset flow is public" do
    get new_user_password_path
    assert_response :success
  end

  test "setup wizard is not gated behind sign-in" do
    get setup_path
    # Setup is complete here, so it bounces to root — the point is it does NOT
    # redirect to the sign-in page.
    assert_not_equal new_user_session_path, URI(response.location.to_s).path if response.redirect?
  end
end
