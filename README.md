# Running Leaderboard

A Ruby on Rails application for tracking running times and maintaining leaderboards for 5ks and Broncos. The app integrates with Strava to automatically sync running data and allows manual entry of race times.

## What This App Does

The Running Leaderboard application provides:

- **User Management**: Registration and authentication system for runners
- **Race Tracking**: Support for different race types (5K, Bronco)
- **Strava Integration**: Automatic synchronization of running data from Strava
- **Manual Entry**: Ability to manually add race times
- **Leaderboards**: Display rankings and performance tracking
- **Admin Features**: Administrative controls for managing users and races
- **Race Deadlines**: Configurable deadlines for different race types

## Prerequisites

- Ruby 3.x
- Rails 8.x
- SQLite3
- Docker (for deployment)

## How to Clone and Run

### 1. Clone the Repository

```bash
git clone <your-repository-url>
cd Running_Leaderboards
```

### 2. Install Dependencies

```bash
bundle install
```

### 3. Database Setup

```bash
rails db:create
rails db:migrate
rails db:seed
```

### 4. Environment Configuration

You'll need 2 credential files:
- config/master.key with the rails key thing
- config/kamal_registry_password.key
- I've also loaded all the strava token details into rails credentials

### 5. Start the Application

```bash
rails server
```

The application will be available at `http://localhost:3000`

## How to Deploy

This application uses Kamal for deployment. The deployment configuration is in `config/deploy.yml`.

### Prerequisites for Deployment

- Docker installed on your local machine
- Access to the target server (configured in `config/deploy.yml`) 192.168.1.70
- Docker registry access (ryansheridan/running-leaderboard)

### Deploy Steps

1. **Build and push the Docker image**:
   ```bash
   kamal setup
   ```

2. **Deploy to production**:
   ```bash
   kamal deploy
   ```


## How to Run Tests

This application uses Rails' built-in testing framework (Minitest).

### Run All Tests

```bash
rails test
```

### Run Specific Test Types

```bash
# Run model tests
rails test test/models/

# Run controller tests
rails test test/controllers/

# Run integration tests
rails test test/integration/

# Run system tests
rails test:system
```

### Run a Specific Test File

```bash
rails test test/models/user_test.rb
```



## Key Features

- **Strava Sync**: Automated background jobs for syncing Strava data
- **Race Types**: Support for 5K and Bronco race categories
- **User Roles**: Admin and regular user permissions
- **Responsive Design**: Mobile-friendly interface
- **PWA Ready**: Progressive Web App capabilities
