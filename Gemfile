# frozen_string_literal: true

source "https://rubygems.org"
ruby "3.4.13"

# 6.1 does not run on Ruby 3.4. 8.1 matches Vapor.
gem "activesupport", "~> 8.1.0"
# Ruby 3.4 no longer ships csv as a default gem. httparty 0.21 requires it.
gem "csv"
gem "figaro"
gem "honeybadger"
gem "httparty"
# 1.13 does not support Ruby 3.4.
gem "nokogiri", "~> 1.18.8"
# Ruby 3.4 warns that ostruct leaves the default gems in 4.0. rake still loads it.
gem "ostruct"
gem "rake"
gem "redis"
gem "require_all", "~> 1.5"
gem "resque", "~> 2.0.0"
gem "rubocop", "~> 0.49.1", require: false
# 1.1 references DidYouMean::SPELL_CHECKERS, removed in Ruby 3.4.
gem "thor", "~> 1.3.2"

group :test do
  # 3.13 is compatible with ActiveSupport 8.1's Object#with.
  gem "rspec", "~> 3.13"
  gem "rspec_junit_formatter"
end

group :development, :test do
  gem "pry"
  gem "pry-nav"
  gem "pry-rescue"
end
