require "test_helper"

class ProgramQualificationTest < ActiveSupport::TestCase
  setup do
    @village = Village.create!(name: "Test Village", setup_complete: true)
    @program = Program.create!(name: "Test Program", village: @village)
    @qualification = Qualification.create!(
      name: "Test Qualification",
      description: "Test description",
      village: @village
    )
  end

  test "program qualification is valid with program and qualification" do
    prog_qual = ProgramQualification.new(program: @program, qualification: @qualification)
    assert prog_qual.valid?
  end

  test "program qualification requires program" do
    prog_qual = ProgramQualification.new(qualification: @qualification)
    assert_not prog_qual.valid?
    assert_includes prog_qual.errors[:program], "must exist"
  end

  test "program qualification requires qualification" do
    prog_qual = ProgramQualification.new(program: @program)
    assert_not prog_qual.valid?
    assert_includes prog_qual.errors[:qualification], "must exist"
  end

  test "program qualification is unique per program and qualification" do
    ProgramQualification.create!(program: @program, qualification: @qualification)
    duplicate = ProgramQualification.new(program: @program, qualification: @qualification)
    assert_not duplicate.valid?
  end

  test "program can have multiple different qualifications" do
    qual2 = Qualification.create!(name: "Another Qual", description: "Another description", village: @village)
    ProgramQualification.create!(program: @program, qualification: @qualification)
    prog_qual2 = ProgramQualification.new(program: @program, qualification: qual2)
    assert prog_qual2.valid?
  end

  test "same qualification can be required by multiple programs" do
    program2 = Program.create!(name: "Another Program", village: @village)
    ProgramQualification.create!(program: @program, qualification: @qualification)
    prog_qual2 = ProgramQualification.new(program: program2, qualification: @qualification)
    assert prog_qual2.valid?
  end

  test "deleting program qualification does not delete program" do
    prog_qual = ProgramQualification.create!(program: @program, qualification: @qualification)
    prog_qual.destroy
    assert Program.exists?(@program.id)
  end

  test "deleting program qualification does not delete qualification" do
    prog_qual = ProgramQualification.create!(program: @program, qualification: @qualification)
    prog_qual.destroy
    assert Qualification.exists?(@qualification.id)
  end

  test "deleting program deletes program qualifications" do
    ProgramQualification.create!(program: @program, qualification: @qualification)
    assert_difference "ProgramQualification.count", -1 do
      @program.destroy
    end
  end
end
