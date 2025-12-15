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
end
