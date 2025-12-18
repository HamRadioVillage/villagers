require "test_helper"

class VillageTest < ActiveSupport::TestCase
  test "village requires name" do
    village = Village.new(setup_complete: true)
    assert_not village.valid?
    assert_includes village.errors[:name], "can't be blank"
  end

  test "village is valid with name" do
    village = Village.new(name: "Test Village", setup_complete: true)
    assert village.valid?
  end

  test "setup_complete defaults to false" do
    village = Village.new(name: "Test Village")
    assert_not village.setup_complete
  end

  test "setup_complete can be set to true" do
    village = Village.create!(name: "Test Village", setup_complete: true)
    assert village.setup_complete
  end

  test "village has many programs" do
    village = Village.create!(name: "Test Village", setup_complete: true)
    program = Program.create!(name: "Test Program", village: village)
    assert_includes village.programs, program
  end

  test "village has many qualifications" do
    village = Village.create!(name: "Test Village", setup_complete: true)
    qualification = Qualification.create!(name: "Test Qual", description: "Test description", village: village)
    assert_includes village.qualifications, qualification
  end

  # Email configuration tests
  test "email_enabled defaults to false" do
    village = Village.new(name: "Test Village")
    assert_not village.email_enabled?
  end

  test "mailgun_api_key required when email enabled" do
    village = Village.new(name: "Test Village", email_enabled: true, mailgun_domain: "mg.example.com")
    assert_not village.valid?
    assert_includes village.errors[:mailgun_api_key], "can't be blank"
  end

  test "mailgun_domain required when email enabled" do
    village = Village.new(name: "Test Village", email_enabled: true, mailgun_api_key: "key-123")
    assert_not village.valid?
    assert_includes village.errors[:mailgun_domain], "can't be blank"
  end

  test "mailgun settings not required when email disabled" do
    village = Village.new(name: "Test Village", email_enabled: false)
    assert village.valid?
  end

  test "valid with complete mailgun settings when email enabled" do
    village = Village.new(
      name: "Test Village",
      email_enabled: true,
      mailgun_api_key: "key-123",
      mailgun_domain: "mg.example.com",
      mailgun_region: "us"
    )
    assert village.valid?
  end

  test "mailgun_region must be us or eu" do
    village = Village.new(name: "Test", mailgun_region: "invalid")
    assert_not village.valid?
    assert_includes village.errors[:mailgun_region], "is not included in the list"
  end

  test "email_enabled? class method returns false when no village" do
    Village.destroy_all
    assert_not Village.email_enabled?
  end

  test "email_enabled? class method returns false when setup incomplete" do
    Village.destroy_all
    Village.create!(name: "Test", setup_complete: false)
    assert_not Village.email_enabled?
  end

  test "email_enabled? class method returns village setting" do
    Village.destroy_all
    Village.create!(
      name: "Test",
      setup_complete: true,
      email_enabled: true,
      mailgun_api_key: "key-123",
      mailgun_domain: "mg.example.com"
    )
    assert Village.email_enabled?
  end

  test "mailgun_settings returns empty hash when no village" do
    Village.destroy_all
    assert_equal({}, Village.mailgun_settings)
  end

  test "mailgun_settings returns settings hash" do
    Village.destroy_all
    Village.create!(
      name: "Test",
      setup_complete: true,
      email_enabled: true,
      mailgun_api_key: "key-123",
      mailgun_domain: "mg.example.com",
      mailgun_region: "eu"
    )

    settings = Village.mailgun_settings
    assert_equal "key-123", settings[:api_key]
    assert_equal "mg.example.com", settings[:domain]
    assert_equal "eu", settings[:region]
  end
end
