require "test_helper"

class UserPolicyTest < ActiveSupport::TestCase
  setup do
    @village = Village.create!(name: "Test Village", setup_complete: true)
    @target_user = User.create!(
      email: "target@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @volunteer = User.create!(
      email: "volunteer@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @village_admin = User.create!(
      email: "admin@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    village_admin_role = Role.find_or_create_by!(name: Role::VILLAGE_ADMIN)
    UserRole.create!(user: @village_admin, role: village_admin_role)
  end

  # Index tests
  test "index allowed for village admin" do
    assert UserPolicy.new(@village_admin, User).index?
  end

  test "index denied for volunteer" do
    assert_not UserPolicy.new(@volunteer, User).index?
  end

  test "index denied for nil user" do
    assert_not UserPolicy.new(nil, User).index?
  end

  # Show tests
  test "show allowed for village admin" do
    assert UserPolicy.new(@village_admin, @target_user).show?
  end

  test "show denied for volunteer" do
    assert_not UserPolicy.new(@volunteer, @target_user).show?
  end

  test "show denied for nil user" do
    assert_not UserPolicy.new(nil, @target_user).show?
  end

  # Edit tests
  test "edit allowed for village admin" do
    assert UserPolicy.new(@village_admin, @target_user).edit?
  end

  test "edit denied for volunteer" do
    assert_not UserPolicy.new(@volunteer, @target_user).edit?
  end

  test "edit denied for nil user" do
    assert_not UserPolicy.new(nil, @target_user).edit?
  end

  # Update tests
  test "update allowed for village admin" do
    assert UserPolicy.new(@village_admin, @target_user).update?
  end

  test "update denied for volunteer" do
    assert_not UserPolicy.new(@volunteer, @target_user).update?
  end

  test "update denied for nil user" do
    assert_not UserPolicy.new(nil, @target_user).update?
  end

  # Grant qualification tests
  test "grant_qualification allowed for village admin" do
    assert UserPolicy.new(@village_admin, @target_user).grant_qualification?
  end

  test "grant_qualification denied for volunteer" do
    assert_not UserPolicy.new(@volunteer, @target_user).grant_qualification?
  end

  test "grant_qualification denied for nil user" do
    assert_not UserPolicy.new(nil, @target_user).grant_qualification?
  end

  # Scope tests
  test "scope returns all users for village admin" do
    scope = UserPolicy::Scope.new(@village_admin, User).resolve
    assert_includes scope, @target_user
    assert_includes scope, @volunteer
    assert_includes scope, @village_admin
  end

  test "scope returns no users for volunteer" do
    scope = UserPolicy::Scope.new(@volunteer, User).resolve
    assert_empty scope
  end

  test "scope returns no users for nil user" do
    scope = UserPolicy::Scope.new(nil, User).resolve
    assert_empty scope
  end
end
