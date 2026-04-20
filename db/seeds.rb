Dir[Rails.root.join("db/seeds/*.rb")].sort.each { |f| load f }

puts "\nSeed complete!"
puts "  Teams: #{Team.count} (NFL: #{Team.nfl.count}, NCAA: #{Team.ncaa.count}, FIFA: #{Team.fifa.count})"
puts "  People: #{Person.count} (Athletes: #{Person.where(athlete: true).count})"
puts "  Athletes: #{Athlete.count}"
puts "  Contracts: #{Contract.count}"
