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
# Note: usernames are case-insensitive and will be normalized to lowercase
User.find_or_create_by!(username: "ryans".downcase) do |user|
  user.firstname = "Ryan"
  user.lastname = "Sheridan"
  user.password = "1234"
  user.strava_username = "ryans"
  user.admin = true
end

User.find_or_create_by!(username: "nickb".downcase) do |user|
  user.firstname = "Nick"
  user.lastname = "Bielby"
  user.strava_username = "nickb"
  user.password = "1234"
  user.admin = true
end

# rails runner "puts 'Ryan user id: ' + (User.find_by(username: 'ryans')&.id ).to_s"

# Create regular users without passwords
users_data = [
  [ "Alex", "Dewhurst" ],
  [ "Andrew", "van Gemst" ],
  [ "Andrew", "Snijders" ],
  [ "Andy", "Huang" ],
  [ "Benjamin", "Coubrough" ],
  [ "Ben", "McLanahan" ],
  [ "Billy", "Maui" ],
  [ "Bryan", "Daniels-Fok" ],
  [ "Charlie", "Ellis" ],
  [ "Cooper", "McCone" ],
  [ "Darren", "Leishman" ],
  [ "Elliot", "Stephenson" ],
  [ "Finlay", "Armstrong" ],
  [ "Gatsby", "Cohen" ],
  [ "Harrison", "Coubrough" ],
  [ "Havik", "Ford" ],
  [ "Hunter", "Kao" ],
  [ "Jacob", "Martin" ],
  [ "James", "Bowen" ],
  [ "James", "Ogilvie" ],
  [ "Jamie", "Love" ],
  [ "Josh", "Jack" ],
  [ "Joshua", "Lee" ],
  [ "Lachlan", "Brill" ],
  [ "Luke", "Dillon-Price" ],
  [ "Luke", "Dowle" ],
  [ "Malachi", "Symons" ],
  [ "Matthew", "Connelly" ],
  [ "Michael", "James" ],
  [ "Nathan", "Davies" ],
  [ "Noah", "Wood" ],
  [ "Oakley", "Cowie" ],
  [ "Oli", "Pitts" ],
  [ "Ollie", "Pugh" ],
  [ "Ori", "Hoskin" ],
  [ "Rasmus", "Hunt" ],
  [ "Rian", "Caffrey" ],
  [ "Ridhwan", "Singh" ],
  [ "River", "Read - Smith" ],
  [ "Samuel", "Worsley" ],
  [ "Sebastian", "Strydom" ],
  [ "Toby", "Connor-Kebbell" ],
  [ "Troy", "Craddock" ],
  [ "Victor", "Stanley" ],
  [ "Vinay", "Varadarajan" ]
]

users_data.each do |firstname, lastname|
  # Generate username from firstname + first letter of lastname
  base_username = "#{firstname.downcase.gsub(/[^a-z0-9]/, '')}#{lastname.first.downcase}"

  # Handle special cases for duplicate names
  candidate = base_username
  counter = 1
  while User.exists?(username: candidate)
    candidate = "#{base_username}#{counter}"
    counter += 1
  end

  User.find_or_create_by!(username: candidate) do |user|
    user.firstname = firstname
    user.lastname = lastname
    user.admin = false
    # Note: No password set initially - users will set password on first login
  end
end

puts "Seed data created successfully!"
puts "Created #{User.count} users total"
puts "Admin users: username='ryans', password='1234'"
puts "           : username='nickb', password='1234'"
puts "Regular users: No password set - will be prompted to create password on first login"
