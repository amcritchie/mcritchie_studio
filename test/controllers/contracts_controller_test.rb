require "test_helper"

class ContractsControllerTest < ActionDispatch::IntegrationTest
  test "contracts page loads" do
    get nfl_contracts_path
    assert_response :success
    assert_select "h1", /NFL Contracts/
  end

  test "contracts page shows player name" do
    get nfl_contracts_path
    assert_response :success
    assert_select "td", /Allen/
  end

  test "contracts sorts by team" do
    get nfl_contracts_path(sort: "team")
    assert_response :success
  end

  test "contracts sorts by name" do
    get nfl_contracts_path(sort: "name")
    assert_response :success
  end

  test "contracts sorts by position" do
    get nfl_contracts_path(sort: "position")
    assert_response :success
  end

  test "contracts supports search" do
    get nfl_contracts_path(search: "allen")
    assert_response :success
    assert_select "td", /Allen/
  end

  test "contracts filters by type" do
    get nfl_contracts_path(type: "active")
    assert_response :success
  end
end
