# frozen_string_literal: true

require "rubygems"
require "bundler/setup"
Bundler.require(:default)
require_all "lib"
require "active_support/all"

def app_init
  configure_figaro
  configure_honeybadger
  setup_resque
end

def configure_honeybadger
  Honeybadger.start(Honeybadger::Config.new(env: ENV["NAMESPACE"]))
end

def configure_figaro
  Figaro.application = Figaro::Application.new(environment: ENV["NAMESPACE"],
                                               path: "config/application.yml")
  Figaro.load
end

def setup_resque
  Resque.redis = Redis.new(host: ENV["REDIS_HOST"], port: ENV["REDIS_PORT"])
end
