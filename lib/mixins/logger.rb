require 'logger'

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
    level = ENV["LOG_LEVEL"].to_s.downcase
    if level == "error"
      Logger::ERROR
    elsif level == "warn"
      Logger::WARN
    elsif level == "info"
      Logger::INFO
    else
      Logger::DEBUG
    end
  end
end
