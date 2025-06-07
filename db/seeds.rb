# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

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

puts "Seed data created successfully!"
puts "Admin user: username='ryans', password='1234'"
puts ""
puts "To load play fixtures (events, users, plays), run:"
puts "  rails db:fixtures:load FIXTURES=events,users,plays"
