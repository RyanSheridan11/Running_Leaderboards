# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create admin user if not exists
User.find_or_create_by!(username: "ryan") do |user|
  user.password = "1234"
  user.admin = true
end

User.find_or_create_by!(username: "nick") do |user|
  user.password = "1234"
  user.admin = true
end

# Create regular user if not exists
regular_user = User.find_or_create_by!(username: "testuser") do |user|
  user.password = "password"
  user.admin = false
end

# Create some test plays for approval workflow
unless Play.exists?
  # Pending plays
  Play.create!(
    title: "Havik D -> Callahan",
    description: "Very sick play",
    video_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    user: regular_user,
    status: "pending"
  )
  Play.create!(title: "Play 1", description: "Very sick play", user: regular_user)
  Play.create!(title: "Play 2", description: "Very sick play", user: regular_user)
  Play.create!(title: "Play 3", description: "Very sick play", user: regular_user)
  Play.create!(title: "Play 4", description: "Very sick play", user: regular_user)
  Play.create!(title: "Play 5", description: "Very sick play", user: regular_user)
  Play.create!(title: "Play 6", description: "Very sick play", user: regular_user)
  Play.create!(title: "Play 7", description: "Very sick play", user: regular_user)
  Play.create!(title: "Play 8", description: "Very sick play", user: regular_user)
  Play.create!(title: "Play 9", description: "Very sick play", user: regular_user)
  Play.create!(title: "Play 10", description: "Very sick play", user: regular_user)
  Play.create!(title: "Play 11", description: "Very sick play", user: regular_user)


  puts "Created #{Play.count} test plays"
end

# Create additional users and random run data
names = [
  'Darren Leishman', 'James Bowen', 'Ben Coubrough', 'Harry Coubrough',
  'Michael James', 'Troy Craddock', 'Finlay Armstrong', 'Andy Huang',
  'Cooper McCone', 'Alex Dewhurst', 'Gatsby Cohen'
]

names.each do |full_name|
  username = full_name.parameterize(separator: '_')
  user = User.find_or_create_by!(username: username) do |u|
    u.password = 'password'
    u.admin    = false
  end

  # Skip if runs already exist for idempotency
  next if user.runs.exists?

  # Generate 3 random 5k runs (time between 20 and 30 minutes)
  3.times do
    Run.create!(
      user: user,
      race_type: '5k',
      date: Date.today - rand(0..30),
      time: rand(20*60..30*60)
    )
  end

  # Generate 2 random Bronco runs (time between 90 and 150 seconds)
  2.times do
    Run.create!(
      user: user,
      race_type: 'bronco',
      date: Date.today - rand(0..30),
      time: rand(90..150)
    )
  end
end

puts "Seed data created successfully!"
puts "Admin user: username='ryan', password='1234'"
puts "Regular user: username='testuser', password='password'"
puts "Created sample runs for users: #{names.join(', ')}"

# Seed events
events = [
  { name: 'Youth Champs',   start_date: Date.new(2025, 6, 1), end_date: Date.new(2025, 6, 3) },
  { name: 'Camp 1',         start_date: Date.new(2025, 6, 5), end_date: Date.new(2025, 6, 7) },
  { name: 'Camp 2',         start_date: Date.new(2025, 6, 9), end_date: Date.new(2025, 6, 11) },
  { name: 'Camp 3',         start_date: Date.new(2025, 6, 13), end_date: Date.new(2025, 6, 15) },
  { name: 'Trans Tasman',   start_date: Date.new(2025, 6, 17), end_date: Date.new(2025, 6, 19) },
  { name: 'Camp 4',         start_date: Date.new(2025, 6, 21), end_date: Date.new(2025, 6, 23) },
  { name: 'Camp 5',         start_date: Date.new(2025, 6, 25), end_date: Date.new(2025, 6, 27) },
  { name: 'Camp 6',         start_date: Date.new(2025, 6, 29), end_date: Date.new(2025, 7, 1) },
  { name: 'World Champs',   start_date: Date.new(2025, 7, 3), end_date: Date.new(2025, 7, 5) }
]
events.each do |attrs|
  Event.find_or_create_by!(name: attrs[:name]) do |e|
    e.start_date = attrs[:start_date]
    e.end_date   = attrs[:end_date]
  end
end
puts "Seeded #{Event.count} events"
