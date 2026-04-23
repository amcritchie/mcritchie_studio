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

  # --- find_by_name tests ---

  test "find_by_name finds exact slug match" do
    found = Person.find_by_name("Lionel", "Messi")
    assert_equal people(:messi), found
  end

  test "find_by_name finds normalized slug (strips periods)" do
    person = Person.create!(first_name: "JT", last_name: "Tuimoloau")
    found = Person.find_by_name("J.T.", "Tuimoloau")
    assert_equal person, found
  end

  test "find_by_name finds alias match" do
    person = people(:cam_ward)
    person.update!(aliases: ["Cam Ward", "Cameron Ward"])
    # The slug is cam-ward, so searching for Cameron Ward (slug: cameron-ward) won't match slug.
    # But it should match via alias.
    found = Person.find_by_name("Cameron", "Ward")
    assert_equal person, found
  end

  test "find_by_name returns nil when not found" do
    found = Person.find_by_name("Nonexistent", "Player")
    assert_nil found
  end

  # --- find_or_create_by_name! tests ---

  test "find_or_create_by_name! finds existing person" do
    existing = people(:messi)
    found = Person.find_or_create_by_name!("Lionel", "Messi", athlete: true)
    assert_equal existing, found
    assert_no_difference "Person.count" do
      Person.find_or_create_by_name!("Lionel", "Messi")
    end
  end

  test "find_or_create_by_name! creates new person when not found" do
    person = nil
    assert_difference "Person.count", 1 do
      person = Person.find_or_create_by_name!("Zach", "Newguy", athlete: true)
    end
    assert_equal "Zach", person.first_name
    assert_equal "Newguy", person.last_name
    assert person.athlete?
  end

  test "find_or_create_by_name! auto-adds alias when name differs" do
    person = Person.create!(first_name: "JT", last_name: "Tuimoloau")
    assert_empty person.aliases

    found = Person.find_or_create_by_name!("J.T.", "Tuimoloau")
    assert_equal person, found
    assert_includes found.reload.aliases, "J.T. Tuimoloau"
  end

  test "find_or_create_by_name! does not duplicate aliases" do
    person = Person.create!(first_name: "JT", last_name: "Tuimoloau", aliases: ["J.T. Tuimoloau"])
    Person.find_or_create_by_name!("J.T.", "Tuimoloau")
    assert_equal 1, person.reload.aliases.count { |a| a == "J.T. Tuimoloau" }
  end
end
