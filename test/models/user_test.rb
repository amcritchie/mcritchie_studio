require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "display_name returns name when present" do
    user = users(:alex)
    assert_equal "Alex McRitchie", user.display_name
  end

  test "display_name returns capitalized email prefix when name is blank" do
    user = User.create!(email: "newuser@example.com", password: "password")
    assert_equal "Newuser", user.display_name
  end

  test "admin? returns true for admin role" do
    assert users(:alex).admin?
  end

  test "admin? returns false for viewer role" do
    assert_not users(:viewer).admin?
  end

  test "slug is set on save" do
    user = users(:alex)
    user.save!
    assert user.slug.present?
  end

  test "to_param returns slug" do
    user = users(:alex)
    user.save!
    assert_equal user.slug, user.to_param
  end

  test "avatar_initials returns first letter of name" do
    user = users(:alex)
    assert_equal "A", user.avatar_initials
  end

  test "avatar_initials uses email when no name" do
    user = User.create!(email: "test@example.com", password: "password")
    assert_equal "T", user.avatar_initials
  end

  test "avatar_color is deterministic" do
    user = users(:alex)
    color1 = user.avatar_color
    color2 = user.avatar_color
    assert_equal color1, color2
    assert_match(/^#[0-9A-Fa-f]{6}$/, color1)
  end

  # --- from_omniauth tests ---

  def google_auth(email: "newgoogle@example.com", name: "Google User", uid: "123456")
    OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: { email: email, name: name }
    )
  end

  test "from_omniauth creates new user when no match" do
    auth = google_auth

    assert_difference "User.count", 1 do
      user = User.from_omniauth(auth)
      assert_equal "newgoogle@example.com", user.email
      assert_equal "Google User", user.name
      assert_equal "google_oauth2", user.provider
      assert_equal "123456", user.uid
    end
  end

  test "from_omniauth links existing user by email" do
    alex = users(:alex)
    auth = google_auth(email: alex.email, uid: "99999")

    assert_no_difference "User.count" do
      user = User.from_omniauth(auth)
      assert_equal alex.id, user.id
      assert_equal "google_oauth2", user.provider
      assert_equal "99999", user.uid
    end
  end

  test "from_omniauth returns existing OAuth user" do
    auth = google_auth(email: "oauth@example.com", uid: "55555")
    original = User.from_omniauth(auth)

    assert_no_difference "User.count" do
      returning = User.from_omniauth(auth)
      assert_equal original.id, returning.id
    end
  end
end
