Bundler.require(:default)
require 'active_support/all'
require_all 'lib'
require 'pry'
require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start
