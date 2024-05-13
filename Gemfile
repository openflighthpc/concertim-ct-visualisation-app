source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.1"


###################################
#
# Rails optional Rails parts and puma
#
###################################

gem "rails", "~> 7.1.3"
gem "puma", "~> 6.4"
gem "jbuilder"
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]
# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"


###################################
# 
# Engines
#
###################################


###################################
#
# Database Adapters
#
###################################

gem "pg", "~> 1.5"

# Use Redis adapter to run Action Cable in production
gem "redis", "~> 5.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"


###################################
#
# Authorization and Authentication
#
###################################
gem "devise", "~> 4.9.3"
gem "devise-jwt", ">= 0.10.0"
gem "cancancan", "~> 3.5.0"
gem "sqlite3"

###################################
#
# Assets and Asset pipeline
#
###################################

gem "sprockets-rails"
gem "importmap-rails"

# Pin dartsass-rails to 0.4.1.  Version 0.5.0 has a dependency on sass-embedded
# that doesn't work with dependabot.  Dependabot keeps trying to change
# sass-embedded to a x86_64-linux-gnu variation that doesn't install on either
# the vagrant machine or the github actions machine.  Perhaps there is a better
# fix than this.
gem "dartsass-rails", "= 0.4.1"


###################################
#
# Rendering and view related gems
#
###################################

gem "simple-navigation", "~> 4.4"
gem "cells-rails", "~> 0.1.5"
gem "cells-erb", "~> 0.1.0"
gem "rabl", "~> 0.16.1"
gem "pagy", "~> 6.4"
gem "simple_form", "~> 5.3"
gem "commonmarker", "~> 1.0"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"


###################################
#
# Other third party gems
#
###################################

gem "crack", "~> 0.4.5"
gem "good_job", "~> 3.23"
gem "lograge" 


###################################
#
# Communication with our other apps
#
###################################
gem "faraday", "~> 2.9"
gem "faraday-follow_redirects"


###################################
#
# Development gems
#
###################################

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"

  gem "foreman"
end

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem "rspec-rails", "~> 6.1.2"
  # Included in development to have generators use factory bot instead of
  # fixutres.
  gem "factory_bot_rails", "~> 6.4.3"
end


###################################
#
# Test gems
#
###################################

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem 'faker'
  gem "selenium-webdriver"
end
