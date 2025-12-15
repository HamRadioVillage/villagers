require "test_helper"

class UserQualificationTest < ActiveSupport::TestCase
  setup do
    @village = Village.create!(name: "Test Village", setup_complete: true)
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @qualification = Qualification.create!(
      name: "Test Qualification",
      description: "Test description",
      village: @village
    )
  end

  test "user qualification is valid with user and qualification" do
    user_qual = UserQualification.new(user: @user, qualification: @qualification)
    assert user_qual.valid?
  end

  test "user qualification requires user" do
    user_qual = UserQualification.new(qualification: @qualification)
    assert_not user_qual.valid?
    assert_includes user_qual.errors[:user], "must exist"
  end

  test "user qualification requires qualification" do
    user_qual = UserQualification.new(user: @user)
    assert_not user_qual.valid?
    assert_includes user_qual.errors[:qualification], "must exist"
  end

  test "user qualification is unique per user and qualification" do
    UserQualification.create!(user: @user, qualification: @qualification)
    duplicate = UserQualification.new(user: @user, qualification: @qualification)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user], "has already been taken"
  end

  test "user can have multiple different qualifications" do
    qual2 = Qualification.create!(name: "Another Qual", description: "Another description", village: @village)
    UserQualification.create!(user: @user, qualification: @qualification)
    user_qual2 = UserQualification.new(user: @user, qualification: qual2)
    assert user_qual2.valid?
  end

  test "same qualification can be granted to multiple users" do
    user2 = User.create!(
      email: "user2@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    UserQualification.create!(user: @user, qualification: @qualification)
    user_qual2 = UserQualification.new(user: user2, qualification: @qualification)
    assert user_qual2.valid?
  end

  test "deleting user qualification does not delete user" do
    user_qual = UserQualification.create!(user: @user, qualification: @qualification)
    user_qual.destroy
    assert User.exists?(@user.id)
  end

  test "deleting user qualification does not delete qualification" do
    user_qual = UserQualification.create!(user: @user, qualification: @qualification)
    user_qual.destroy
    assert Qualification.exists?(@qualification.id)
  end

  test "deleting user deletes user qualifications" do
    UserQualification.create!(user: @user, qualification: @qualification)
    assert_difference "UserQualification.count", -1 do
      @user.destroy
    end
  end
end
