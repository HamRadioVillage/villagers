require "test_helper"

class ConferenceRolesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @village = Village.create!(name: "Test Village", setup_complete: true)
    @village_admin = User.create!(
      email: "admin@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @volunteer = User.create!(
      email: "volunteer@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @volunteer2 = User.create!(
      email: "volunteer2@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @conference_lead = User.create!(
      email: "lead@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    village_admin_role = Role.find_or_create_by!(name: Role::VILLAGE_ADMIN)
    UserRole.create!(user: @village_admin, role: village_admin_role)

    @conference = Conference.create!(
      village: @village,
      name: "Test Conference",
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 2.days
    )

    @lead_role = ConferenceRole.create!(
      user: @conference_lead,
      conference: @conference,
      role_name: ConferenceRole::CONFERENCE_LEAD
    )
  end

  # Create tests
  test "should create conference lead role as village admin" do
    sign_in @village_admin
    assert_difference("ConferenceRole.count") do
      post conference_conference_roles_url(@conference), params: {
        user_id: @volunteer.id,
        role_name: ConferenceRole::CONFERENCE_LEAD
      }
    end
    assert_redirected_to @conference
    assert @volunteer.conference_lead?(@conference)
  end

  test "should create conference admin role as village admin" do
    sign_in @village_admin
    assert_difference("ConferenceRole.count") do
      post conference_conference_roles_url(@conference), params: {
        user_id: @volunteer.id,
        role_name: ConferenceRole::CONFERENCE_ADMIN
      }
    end
    assert_redirected_to @conference
    assert @volunteer.conference_admin?(@conference)
  end

  test "should create conference admin role as conference lead" do
    sign_in @conference_lead
    assert_difference("ConferenceRole.count") do
      post conference_conference_roles_url(@conference), params: {
        user_id: @volunteer.id,
        role_name: ConferenceRole::CONFERENCE_ADMIN
      }
    end
    assert_redirected_to @conference
    assert @volunteer.conference_admin?(@conference)
  end

  test "should not create role as regular volunteer" do
    sign_in @volunteer
    assert_no_difference("ConferenceRole.count") do
      post conference_conference_roles_url(@conference), params: {
        user_id: @volunteer2.id,
        role_name: ConferenceRole::CONFERENCE_ADMIN
      }
    end
    assert_redirected_to root_path
  end

  test "should not duplicate existing role" do
    sign_in @village_admin
    # This should find the existing role instead of creating a duplicate
    assert_no_difference("ConferenceRole.count") do
      post conference_conference_roles_url(@conference), params: {
        user_id: @conference_lead.id,
        role_name: ConferenceRole::CONFERENCE_LEAD
      }
    end
    assert_redirected_to @conference
  end

  test "defaults to conference admin role when role_name not specified" do
    sign_in @village_admin
    assert_difference("ConferenceRole.count") do
      post conference_conference_roles_url(@conference), params: {
        user_id: @volunteer.id
      }
    end
    assert @volunteer.conference_admin?(@conference)
  end

  # Destroy tests
  test "should destroy role as village admin" do
    admin_role = ConferenceRole.create!(
      user: @volunteer,
      conference: @conference,
      role_name: ConferenceRole::CONFERENCE_ADMIN
    )
    sign_in @village_admin
    assert_difference("ConferenceRole.count", -1) do
      delete conference_conference_role_url(@conference, admin_role)
    end
    assert_redirected_to @conference
  end

  test "should destroy admin role as conference lead" do
    admin_role = ConferenceRole.create!(
      user: @volunteer,
      conference: @conference,
      role_name: ConferenceRole::CONFERENCE_ADMIN
    )
    sign_in @conference_lead
    assert_difference("ConferenceRole.count", -1) do
      delete conference_conference_role_url(@conference, admin_role)
    end
    assert_redirected_to @conference
  end

  test "should not destroy role as regular volunteer" do
    admin_role = ConferenceRole.create!(
      user: @volunteer,
      conference: @conference,
      role_name: ConferenceRole::CONFERENCE_ADMIN
    )
    sign_in @volunteer2
    assert_no_difference("ConferenceRole.count") do
      delete conference_conference_role_url(@conference, admin_role)
    end
    assert_redirected_to root_path
  end

  test "conference lead cannot remove last conference lead" do
    sign_in @conference_lead
    assert_no_difference("ConferenceRole.count") do
      delete conference_conference_role_url(@conference, @lead_role)
    end
    assert_redirected_to @conference
    follow_redirect!
    assert_match(/Cannot remove the last conference lead/, response.body)
  end

  test "village admin can remove last conference lead" do
    sign_in @village_admin
    assert_difference("ConferenceRole.count", -1) do
      delete conference_conference_role_url(@conference, @lead_role)
    end
    assert_redirected_to @conference
  end

  test "conference lead can remove one of multiple leads" do
    # Add a second lead
    second_lead_role = ConferenceRole.create!(
      user: @volunteer,
      conference: @conference,
      role_name: ConferenceRole::CONFERENCE_LEAD
    )
    sign_in @conference_lead
    assert_difference("ConferenceRole.count", -1) do
      delete conference_conference_role_url(@conference, second_lead_role)
    end
    assert_redirected_to @conference
  end
end
