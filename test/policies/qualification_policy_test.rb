require "test_helper"

class QualificationPolicyTest < ActiveSupport::TestCase
  setup do
    @village = Village.create!(name: "Test Village", setup_complete: true)
    @qualification = Qualification.create!(
      name: "Test Qualification",
      description: "Test description",
      village: @village
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
  test "index allowed for volunteer" do
    # Volunteers can view qualifications list
    assert QualificationPolicy.new(@volunteer, Qualification).index?
  end

  test "index allowed for village admin" do
    assert QualificationPolicy.new(@village_admin, Qualification).index?
  end

  test "index denied for nil user" do
    assert_not QualificationPolicy.new(nil, Qualification).index?
  end

  # Show tests
  test "show allowed for volunteer" do
    # Volunteers can view individual qualification details
    assert QualificationPolicy.new(@volunteer, @qualification).show?
  end

  test "show allowed for village admin" do
    assert QualificationPolicy.new(@village_admin, @qualification).show?
  end

  test "show denied for nil user" do
    assert_not QualificationPolicy.new(nil, @qualification).show?
  end

  # Create tests
  test "create allowed for village admin" do
    assert QualificationPolicy.new(@village_admin, Qualification).create?
  end

  test "create denied for volunteer" do
    assert_not QualificationPolicy.new(@volunteer, Qualification).create?
  end

  test "create denied for nil user" do
    assert_not QualificationPolicy.new(nil, Qualification).create?
  end

  # Update tests
  test "update allowed for village admin" do
    assert QualificationPolicy.new(@village_admin, @qualification).update?
  end

  test "update denied for volunteer" do
    assert_not QualificationPolicy.new(@volunteer, @qualification).update?
  end

  test "update denied for nil user" do
    assert_not QualificationPolicy.new(nil, @qualification).update?
  end

  # Destroy tests
  test "destroy allowed for village admin" do
    assert QualificationPolicy.new(@village_admin, @qualification).destroy?
  end

  test "destroy denied for volunteer" do
    assert_not QualificationPolicy.new(@volunteer, @qualification).destroy?
  end

  test "destroy denied for nil user" do
    assert_not QualificationPolicy.new(nil, @qualification).destroy?
  end

  # Scope tests
  test "scope returns all qualifications" do
    scope = QualificationPolicy::Scope.new(@volunteer, Qualification).resolve
    assert_includes scope, @qualification
  end
end
