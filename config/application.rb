require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require_all 'lib'
require 'active_support/all'

def app_init
  configure_figaro
  configure_honeybadger
  setup_resque
end

def configure_honeybadger
  Honeybadger.start(Honeybadger::Config.new(env: ENV['NAMESPACE']))
end

def configure_figaro
  Figaro.application = Figaro::Application.new(environment: ENV['NAMESPACE'],
                                               path: 'config/application.yml')
  Figaro.load
end

def setup_resque
  if ENV['KUBERNETES'] == 'kube' && ENV['REDIS_OVERRIDE'] != 'true'
    sentinels = [
      { host: ENV['REDIS_SENTINEL_SERVICE_HOST'], port: ENV['REDIS_SENTINEL_SERVICE_PORT'] }
    ]
    Resque.redis = Redis.new(url: 'redis://mymaster', sentinels: sentinels, thread_safe: true)
  else
    ENV['RESQUE_HOST'] ||= 'redis://localhost:6379'

    uri = URI.parse(ENV['RESQUE_HOST'])
    Resque.redis = Redis.new(host: uri.host, port: uri.port, password: uri.password, thread_safe: true)
  end
end
