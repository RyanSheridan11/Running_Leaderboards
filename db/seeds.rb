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
User.find_or_create_by!(username: "testuser") do |user|
  user.password = "password"
  user.admin = false
end

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

# Create some test plays for approval workflow
unless Play.exists?
  # Get Youth Champs event
  youth_champs = Event.find_by(name: 'Youth Champs')

  # Create some users first for the plays
  play_users = []
  [ 'james_bowen', 'ben_coubrough', 'michael_james', 'finlay_armstrong', 'cooper_mccone' ].each do |username|
    user = User.find_or_create_by!(username: username) do |u|
      u.password = 'password'
      u.admin = false
    end
    play_users << user
  end

  # Pending plays
  Play.create!(
    title: "Havik D -> Callahan",
    description: "Very sick play",
    video_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    user: play_users.sample,
    event: youth_champs
  )

  # Create 5 additional plays with random ELO ratings between 900-1100
  play_data = [
    {
      title: "Backhand Hammer to the End Zone",
      description: "Perfect break side throw under pressure",
      video_url: "https://www.youtube.com/watch?v=example1",
      elo: rand(900..1100)
    },
    {
      title: "Layout Grab in Traffic",
      description: "Incredible extension to secure the disc",
      video_url: "https://www.youtube.com/watch?v=example2",
      elo: rand(900..1100)
    },
    {
      title: "Huck to Callahan",
      description: "Long throw intercepted for the score",
      video_url: "https://www.youtube.com/watch?v=example3",
      elo: rand(900..1100)
    },
    {
      title: "Sky over Two Defenders",
      description: "Dominant aerial display at the goal line",
      video_url: "https://www.youtube.com/watch?v=example4",
      elo: rand(900..1100)
    },
    {
      title: "Greatest Save",
      description: "Toe-tap keep alive leading to assist",
      video_url: "https://www.youtube.com/watch?v=example5",
      elo: rand(900..1100)
    }
  ]

  play_data.each do |data|
    Play.create!(
      title: data[:title],
      description: data[:description],
      video_url: data[:video_url],
      user: play_users.sample,
      status: "approved",
      elo: data[:elo],
      event: youth_champs
    )
  end

  puts "Created #{Play.count} test plays for Youth Champs event"
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
puts "Seeded #{Event.count} events"
