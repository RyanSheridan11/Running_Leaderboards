namespace :db do
  desc "Load test plays and runs data"
  task load_test_data: :environment do
    puts "Loading test plays..."

    # Ensure we have a Youth Champs event
    youth_champs = Event.find_or_create_by!(name: "Youth Champs") do |e|
      e.start_date = Date.new(2025, 6, 1)
      e.end_date = Date.new(2025, 6, 3)
    end

    # Clear existing test plays
    Play.where(title: [
      "Backhand Hammer to the End Zone",
      "Layout Grab in Traffic",
      "Huck to Callahan",
      "Sky over Two Defenders",
      "Greatest Save"
    ]).destroy_all

    # Create test plays
    play_data = [
      {
        title: "Backhand Hammer to the End Zone",
        description: "Perfect break side throw under pressure",
        video_url: "https://www.youtube.com/watch?v=example1",
        username: "benjaminc",
        status: "approved",
        elo: 1050
      },
      {
        title: "Layout Grab in Traffic",
        description: "Incredible extension to secure the disc",
        video_url: "https://www.youtube.com/watch?v=example2",
        username: "michaelj",
        status: "approved",
        elo: 980
      },
      {
        title: "Huck to Callahan",
        description: "Long throw intercepted for the score",
        video_url: "https://www.youtube.com/watch?v=example3",
        username: "finlaya",
        status: "approved",
        elo: 1020
      },
      {
        title: "Sky over Two Defenders",
        description: "Dominant aerial display at the goal line",
        video_url: "https://www.youtube.com/watch?v=example4",
        username: "cooperm",
        status: "approved",
        elo: 1100
      },
      {
        title: "Greatest Save",
        description: "Toe-tap keep alive leading to assist",
        video_url: "https://www.youtube.com/watch?v=example5",
        username: "jamesb",
        status: "approved",
        elo: 950
      }
    ]

    play_data.each do |data|
      user = User.find_by_username(data[:username])
      if user
        Play.create!(
          title: data[:title],
          description: data[:description],
          video_url: data[:video_url],
          user: user,
          event: youth_champs,
          status: data[:status],
          elo: data[:elo]
        )
        puts "Created play: #{data[:title]} for #{user.username}"
      else
        puts "Warning: User #{data[:username]} not found, skipping #{data[:title]}"
      end
    end

    puts "Finished loading test plays. Total plays: #{Play.count}"
  end
end
