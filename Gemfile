# frozen_string_literal: true

source "https://rubygems.org"
ruby "2.5.5"

gem "activesupport"
gem "figaro"
gem "honeybadger"
gem "httparty"
gem "nokogiri", "~> 1.12.5"
gem "rake"
gem "redis"
gem "require_all"
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
