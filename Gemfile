# frozen_string_literal: true

source "https://rubygems.org"
ruby "3.0.3"

gem "activesupport"
gem "figaro"
gem "honeybadger"
gem "httparty"
gem "nokogiri", "~> 1.13.1"
gem "rake"
gem "redis"
gem "require_all", "~> 1.5"
gem "resque", "~> 2.0.0"
gem "rubocop", "~> 0.49.1", require: false
gem "thor"

group :test do
  gem "rspec"
  gem "rspec_junit_formatter"
end

group :development, :test do
  gem "pry"
  gem "pry-nav"
  gem "pry-rescue"
end
