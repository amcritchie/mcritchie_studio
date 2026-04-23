require "test_helper"

class ContractTest < ActiveSupport::TestCase
  test "slug is generated from person and team slugs" do
    contract = Contract.create!(person_slug: "neymar-jr", team_slug: "brazil")
    assert_equal "neymar-jr-brazil", contract.slug
  end

  test "belongs to person via slug" do
    contract = contracts(:messi_argentina)
    assert_equal people(:messi), contract.person
  end

  test "belongs to team via slug" do
    contract = contracts(:messi_argentina)
    assert_equal teams(:argentina), contract.team
  end

  test "person_slug and team_slug combo is unique" do
    assert_raises ActiveRecord::RecordInvalid do
      Contract.create!(person_slug: "lionel-messi", team_slug: "argentina")
    end
  end

  test "contract_type must be valid" do
    assert_raises ActiveRecord::RecordInvalid do
      Contract.create!(person_slug: "neymar-jr", team_slug: "brazil", contract_type: "invalid")
    end
  end

  test "contract_type defaults to active" do
    contract = Contract.create!(person_slug: "neymar-jr", team_slug: "brazil")
    assert_equal "active", contract.contract_type
  end

  test "CONTRACT_TYPES includes college active draft_pick mock_pick" do
    assert_equal %w[college active draft_pick mock_pick], Contract::CONTRACT_TYPES
  end
end
