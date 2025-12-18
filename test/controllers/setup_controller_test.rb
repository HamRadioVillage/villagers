require "test_helper"

class SetupControllerTest < ActionDispatch::IntegrationTest
  test "should get show when setup is not complete" do
    get setup_url
    assert_response :success
  end

  test "should redirect from show when setup is complete" do
    Village.create!(name: "Test Village", setup_complete: true)
    get setup_url
    assert_redirected_to root_url
  end

  test "should create village and admin user on valid submission" do
    assert_difference -> { Village.count } => 1, -> { User.count } => 1, -> { UserRole.count } => 1 do
      post setup_url, params: {
        village: { name: "Ham Radio Village" },
        user: {
          email: "admin@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    village = Village.last
    assert_equal "Ham Radio Village", village.name
    assert village.setup_complete?

    user = User.last
    assert_equal "admin@example.com", user.email
    assert user.valid_password?("password123")
    assert user.village_admin?, "Setup user should be assigned village admin role"
  end

  test "should sign in user after successful setup" do
    post setup_url, params: {
      village: { name: "Ham Radio Village" },
      user: {
        email: "admin@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    assert_redirected_to root_path

    # Follow redirect and verify user is signed in
    follow_redirect!
    assert_response :success

    # User should be signed in - verify by checking session or making authenticated request
    user = User.find_by(email: "admin@example.com")
    assert_equal user.id, session["warden.user.user.key"]&.first&.first
  end

  test "should not create village with invalid data" do
    assert_no_difference [ "Village.count", "User.count" ] do
      post setup_url, params: {
        village: { name: "" },
        user: {
          email: "invalid",
          password: "short",
          password_confirmation: "different"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should not allow setup when already complete" do
    Village.create!(name: "Existing Village", setup_complete: true)

    assert_no_difference [ "Village.count", "User.count" ] do
      post setup_url, params: {
        village: { name: "New Village" },
        user: {
          email: "admin@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_redirected_to root_url
  end

  test "should create village with email disabled" do
    post setup_url, params: {
      village: {
        name: "Ham Radio Village",
        email_enabled: "0"
      },
      user: {
        email: "admin@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    village = Village.last
    assert_not village.email_enabled?
    assert_nil village.mailgun_api_key
  end

  test "should create village with email enabled and mailgun settings" do
    post setup_url, params: {
      village: {
        name: "Ham Radio Village",
        email_enabled: "1",
        mailgun_api_key: "key-123456",
        mailgun_domain: "mg.example.com",
        mailgun_region: "us"
      },
      user: {
        email: "admin@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    village = Village.last
    assert village.email_enabled?
    assert_equal "key-123456", village.mailgun_api_key
    assert_equal "mg.example.com", village.mailgun_domain
    assert_equal "us", village.mailgun_region
  end

  test "should fail if email enabled but mailgun settings missing" do
    assert_no_difference [ "Village.count", "User.count" ] do
      post setup_url, params: {
        village: {
          name: "Ham Radio Village",
          email_enabled: "1"
          # Missing mailgun_api_key and mailgun_domain
        },
        user: {
          email: "admin@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "user is auto-confirmed when email is disabled" do
    post setup_url, params: {
      village: {
        name: "Ham Radio Village",
        email_enabled: "0"
      },
      user: {
        email: "admin@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    user = User.find_by(email: "admin@example.com")
    assert user.confirmed?, "User should be auto-confirmed when email is disabled"
  end
end
