set dotenv-load

# Choose a task to run
default:
  just --choose


# Install project tools
prereqs:
  brew bundle install