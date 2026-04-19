require "test_helper"

class PersonTest < ActiveSupport::TestCase
  test "slug is generated from full name" do
    person = Person.create!(first_name: "Kylian", last_name: "Mbappe")
    assert_equal "kylian-mbappe", person.slug
  end

  test "to_param returns slug" do
    person = people(:messi)
    assert_equal "lionel-messi", person.to_param
  end

  test "full_name returns first and last name" do
    person = people(:messi)
    assert_equal "Lionel Messi", person.full_name
  end

  test "first_name is required" do
    person = Person.new(first_name: nil, last_name: "Test")
    assert_not person.valid?
    assert_includes person.errors[:first_name], "can't be blank"
  end

  test "last_name is required" do
    person = Person.new(first_name: "Test", last_name: nil)
    assert_not person.valid?
    assert_includes person.errors[:last_name], "can't be blank"
  end

  test "has many contracts" do
    person = people(:messi)
    assert_respond_to person, :contracts
  end

  test "has many teams through contracts" do
    person = people(:messi)
    assert_includes person.teams, teams(:argentina)
  end
end
