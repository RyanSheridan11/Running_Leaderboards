# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create events if not exists
Event.find_or_create_by!(name: 'Camp 1') do |event|
  event.start_date = Date.new(2025, 6, 5)
  event.end_date = Date.new(2025, 6, 7)
end

Event.find_or_create_by!(name: 'Camp 2') do |event|
  event.start_date = Date.new(2025, 6, 9)
  event.end_date = Date.new(2025, 6, 11)
end

Event.find_or_create_by!(name: 'Camp 3') do |event|
  event.start_date = Date.new(2025, 6, 13)
  event.end_date = Date.new(2025, 6, 15)
end

Event.find_or_create_by!(name: 'Trans Tasman') do |event|
  event.start_date = Date.new(2025, 6, 17)
  event.end_date = Date.new(2025, 6, 19)
end

Event.find_or_create_by!(name: 'Camp 4') do |event|
  event.start_date = Date.new(2026, 6, 21)
  event.end_date = Date.new(2026, 6, 23)
end

Event.find_or_create_by!(name: 'Camp 5') do |event|
  event.start_date = Date.new(2026, 6, 26)
  event.end_date = Date.new(2026, 6, 27)
end

Event.find_or_create_by!(name: 'Camp 6') do |event|
  event.start_date = Date.new(2026, 6, 29)
  event.end_date = Date.new(2026, 7, 1)
end

Event.find_or_create_by!(name: 'World Champs') do |event|
  event.start_date = Date.new(2026, 7, 3)
  event.end_date = Date.new(2026, 7, 5)
end

# Create admin users if not exists
# Note: emails are case-insensitive and will be normalized to lowercase
User.find_or_create_by!(email: "ryansheridan11@gmail.com".downcase) do |user|
  user.firstname = "Ryan"
  user.lastname = "Sheridan"
  user.password = "1234"
  user.strava_username = "ryans"
  user.admin = true
  user.user_type = "coach"
end

User.find_or_create_by!(email: "nick.bielby21@gmail.com".downcase) do |user|
  user.firstname = "Nick"
  user.lastname = "Bielby"
  user.strava_username = "nickb"
  user.password = "1234"
  user.admin = true
  user.user_type = "coach"
end


# Create regular users without passwords
users_data = [
  [ "Alex", "Dewhurst", "alexdewy10@gmail.com" ],
  [ "Andrew", "van Gemst", "andvangemst@gmail.com" ],
  [ "Andrew", "Snijders", "asnijders34@gmail.com" ],
  [ "Andy", "Huang", "andyboyuh9@gmail.com" ],
  [ "Benjamin", "Coubrough", "coubroughbenjamin@gmail.com" ],
  [ "Ben", "McLanahan", "ben@mclanahan.nz" ],
  [ "Billy", "Maui", "billymaui07@gmail.com" ],
  [ "Bryan", "Daniels-Fok", "kevinmfok@gmail.com" ],
  [ "Charlie", "Ellis", "sencharlie0@gmail.com" ],
  [ "Cooper", "McCone", "coopermccone@gmail.com" ],
  [ "Darren", "Leishman", "darren.leishman9@gmail.com" ],
  [ "Elliot", "Stephenson", "es23040@my.westlake.school.nz" ],
  [ "Finlay", "Armstrong", "finlayarmstrong09@gmail.com" ],
  [ "Gatsby", "Cohen", "gatsby.cohen@gmail.com" ],
  [ "Harrison", "Coubrough", "coubroughharris@gmail.com" ],
  [ "Havik", "Ford", "Paubroankids@gmail.com" ],
  [ "Hunter", "Kao", "hunterkao789@gmail.com" ],
  [ "Jacob", "Martin", "jacobmartin.tepuke@gmail.com" ],
  [ "James", "Bowen", "jameslucasbowen@icloud.com" ],
  [ "James", "Ogilvie", "brett.ogilvie@gmail.com" ],
  [ "Jamie", "Love", "ruthlove2176@gmail.com" ],
  [ "Josh", "Jack", "joshjacknz@gmail.com" ],
  [ "Joshua", "Lee", "joshua20090303@gmail.com" ],
  [ "Lachlan", "Brill", "lachlanb.nz@gmail.com" ],
  [ "Luke", "Dillon-Price", "Lukedp500@gmail.com" ],
  [ "Luke", "Dowle", "lukedowle88@gmail.com" ],
  [ "Malachi", "Symons", "joelsymons@gmail.com" ],
  [ "Matthew", "Connelly", "matthew.connelly@fdmc.school.nz" ],
  [ "Michael", "James", "michaeloj21@gmail.com" ],
  [ "Nathan", "Davies", "sharonandjon@hotmail.com" ],
  [ "Noah", "Wood", "woodn6258@gmail.com" ],
  [ "Oakley", "Cowie", "oakley.cowie@example.com" ],
  [ "Oli", "Pitts", "oliverpitts2019@gmail.com" ],
  [ "Ollie", "Pugh", "oliver.k.pugh@gmail.com" ],
  [ "Ori", "Hoskin", "ori.hoskin@gmail.com" ],
  [ "Rasmus", "Hunt", "rasmus.tariki@gmail.com" ],
  [ "Rian", "Caffrey", "rian.caffrey@gmail.com" ],
  [ "Ridhwan", "Singh", "ridhwansingh9@gmail.com" ],
  [ "River", "Read - Smith", "rrrreadsmith@gmail.com" ],
  [ "Samuel", "Worsley", "Lewisworsley@gmail.com" ],
  [ "Sebastian", "Strydom", "stephstrydom@gmail.com" ],
  [ "Toby", "Connor-Kebbell", "toby_ck@icloud.com" ],
  [ "Troy", "Craddock", "troycraddock12@gmail.com" ],
  [ "Victor", "Stanley", "sarastanley8@icloud.com" ],
  [ "Vinay", "Varadarajan", "kavi98@gmail.com" ]
]

users_data.each do |firstname, lastname, email|
  User.find_or_create_by!(email: email.downcase) do |user|
    user.firstname = firstname
    user.lastname = lastname
    user.admin = false
    # Note: No password set initially - users will set password on first login
  end
end

puts "Seed data created successfully!"
puts "Created #{User.count} users total"
puts "Admin users: email='ryan@sheridan.kiwi.nz', password='1234'"
puts "           : email='nick@example.com', password='1234'"
puts "Regular users: No password set - will be prompted to create password on first login"
