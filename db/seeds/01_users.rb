users_data = [
  { name: "Alex McRitchie",  email: "alex@mcritchie.studio",  role: "admin" },
  { name: "Mason McRitchie", email: "mason@mcritchie.studio", role: "admin" },
  { name: "Mack McRitchie",  email: "mack@mcritchie.studio",  role: "admin" },
  { name: "Turf Monster",    email: "turf@mcritchie.studio",  role: "admin" }
]

users_data.each do |data|
  user = User.find_or_create_by!(email: data[:email]) do |u|
    u.name = data[:name]
    u.password = "password"
    u.role = data[:role]
  end
  puts "User: #{user.email} (#{user.role})"
end
