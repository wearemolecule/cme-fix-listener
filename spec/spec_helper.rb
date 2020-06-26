# frozen_string_literal: true

Bundler.require(:default, :test)
require "active_support/all"
require_all "lib"

Time.zone = "Central Time (US & Canada)"

RSpec.configure do |config|
  config.before(:each) do
    some_logger = double("some logger").as_null_object
    allow(Logging).to receive(:logger).and_return(some_logger)
  end
end
