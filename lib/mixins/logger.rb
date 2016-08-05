# frozen_string_literal: true
require 'logger'

# The Logging module can be included in any class to provide leveled logging via Logger standard lib.
module Logging
  def logger
    Logging.logger
  end

  def self.logger
    @logger ||= Logger.new(STDOUT)
    @logger.level = log_level
    @logger
  end

  def self.log_level
    level = ENV['LOG_LEVEL'].to_s.downcase
    if level == 'error'
      Logger::ERROR
    elsif level == 'warn'
      Logger::WARN
    elsif level == 'info'
      Logger::INFO
    else
      Logger::DEBUG
    end
  end
end
